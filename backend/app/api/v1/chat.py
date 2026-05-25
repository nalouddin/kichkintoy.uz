"""
Chat tizimi: REST API + WebSocket (real-time).

REST: tarixni olish, xabar yuborish (HTTP fallback)
WebSocket: real-time xabarlar
"""
import uuid
import json
from datetime import datetime
from typing import Dict, Set
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_, func, update
from pydantic import BaseModel, Field

from app.core.database import get_db, AsyncSessionLocal
from app.core.security import decode_token
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.message import Message, MessageType
from app.dependencies import get_current_user


router = APIRouter(prefix="/chat", tags=["Chat"])


# ============ SCHEMAS ============

class MessageCreate(BaseModel):
    receiver_id: uuid.UUID
    content: str = Field(..., min_length=1, max_length=2000)
    message_type: MessageType = MessageType.TEXT
    file_url: str | None = None


class MessageResponse(BaseModel):
    id: uuid.UUID
    sender_id: uuid.UUID
    receiver_id: uuid.UUID
    content: str
    message_type: MessageType
    file_url: str | None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ConversationPreview(BaseModel):
    """Suhbat ro'yxati uchun (chat list)."""
    user_id: uuid.UUID
    full_name: str
    avatar_url: str | None
    last_message: str
    last_message_at: datetime
    unread_count: int


# ============ WEBSOCKET MANAGER ============

class ConnectionManager:
    """Faol WebSocket ulanishlarini boshqaradi.
    
    user_id → connected WebSocket sockets
    """
    def __init__(self):
        self.active: Dict[uuid.UUID, Set[WebSocket]] = {}

    async def connect(self, user_id: uuid.UUID, websocket: WebSocket):
        await websocket.accept()
        self.active.setdefault(user_id, set()).add(websocket)
        print(f"🟢 User {user_id} connected. Total: {sum(len(s) for s in self.active.values())}")

    def disconnect(self, user_id: uuid.UUID, websocket: WebSocket):
        if user_id in self.active:
            self.active[user_id].discard(websocket)
            if not self.active[user_id]:
                del self.active[user_id]
        print(f"🔴 User {user_id} disconnected.")

    async def send_to_user(self, user_id: uuid.UUID, data: dict):
        """Bitta foydalanuvchining barcha qurilmalariga yuborish."""
        if user_id not in self.active:
            return False
        dead = set()
        for ws in self.active[user_id]:
            try:
                await ws.send_json(data)
            except Exception:
                dead.add(ws)
        # O'lik ulanishlarni tozalash
        for ws in dead:
            self.active[user_id].discard(ws)
        return True


manager = ConnectionManager()


# ============ REST ENDPOINTS ============

@router.post("/messages", response_model=MessageResponse, status_code=201)
async def send_message(
    data: MessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Xabar yuborish (HTTP). WebSocket orqali real-time yetkazadi."""
    # Qabul qiluvchi mavjudligini tekshirish
    receiver_result = await db.execute(select(User).where(User.id == data.receiver_id))
    if not receiver_result.scalar_one_or_none():
        raise HTTPException(404, "Qabul qiluvchi topilmadi")

    msg = Message(
        sender_id=current_user.id,
        receiver_id=data.receiver_id,
        content=data.content,
        message_type=data.message_type,
        file_url=data.file_url,
    )
    db.add(msg)
    await db.flush()
    await db.refresh(msg)

    # Real-time yetkazish
    payload = {
        "type": "new_message",
        "message": {
            "id": str(msg.id),
            "sender_id": str(msg.sender_id),
            "receiver_id": str(msg.receiver_id),
            "content": msg.content,
            "message_type": msg.message_type.value,
            "file_url": msg.file_url,
            "is_read": msg.is_read,
            "created_at": msg.created_at.isoformat(),
        },
    }
    await manager.send_to_user(data.receiver_id, payload)

    return msg


@router.get("/conversations", response_model=list[ConversationPreview])
async def get_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Joriy foydalanuvchining barcha suhbatlari ro'yxati."""
    # Eng oxirgi xabar har bir kontakt uchun
    # Birinchi - hamma kontaktlarni topamiz
    sent = await db.execute(
        select(Message.receiver_id)
        .where(Message.sender_id == current_user.id)
        .distinct()
    )
    received = await db.execute(
        select(Message.sender_id)
        .where(Message.receiver_id == current_user.id)
        .distinct()
    )
    contact_ids = {r[0] for r in sent.all()} | {r[0] for r in received.all()}

    conversations = []
    for contact_id in contact_ids:
        # Oxirgi xabar
        last_msg_result = await db.execute(
            select(Message)
            .where(
                or_(
                    and_(Message.sender_id == current_user.id, Message.receiver_id == contact_id),
                    and_(Message.sender_id == contact_id, Message.receiver_id == current_user.id),
                )
            )
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        last_msg = last_msg_result.scalar_one_or_none()
        if not last_msg:
            continue

        # O'qilmagan
        unread_result = await db.execute(
            select(func.count(Message.id)).where(
                Message.sender_id == contact_id,
                Message.receiver_id == current_user.id,
                Message.is_read == False,
            )
        )
        unread = unread_result.scalar() or 0

        # Kontakt ma'lumoti
        contact_result = await db.execute(select(User).where(User.id == contact_id))
        contact = contact_result.scalar_one_or_none()
        if not contact:
            continue

        conversations.append(
            ConversationPreview(
                user_id=contact.id,
                full_name=contact.full_name,
                avatar_url=contact.avatar_url,
                last_message=last_msg.content[:100],
                last_message_at=last_msg.created_at,
                unread_count=unread,
            )
        )

    # Vaqt bo'yicha tartiblash (yangi yuqorida)
    conversations.sort(key=lambda c: c.last_message_at, reverse=True)
    return conversations


@router.get("/messages/{other_user_id}", response_model=list[MessageResponse])
async def get_messages(
    other_user_id: uuid.UUID,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Ikki foydalanuvchi o'rtasidagi xabarlar tarixi."""
    result = await db.execute(
        select(Message)
        .where(
            or_(
                and_(
                    Message.sender_id == current_user.id,
                    Message.receiver_id == other_user_id,
                ),
                and_(
                    Message.sender_id == other_user_id,
                    Message.receiver_id == current_user.id,
                ),
            )
        )
        .order_by(Message.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    messages = list(result.scalars().all())

    # Barcha kelgan xabarlarni o'qildi deb belgilash
    await db.execute(
        update(Message)
        .where(
            Message.sender_id == other_user_id,
            Message.receiver_id == current_user.id,
            Message.is_read == False,
        )
        .values(is_read=True)
    )

    messages.reverse()  # eski yuqorida, yangi pastda
    return messages


@router.get("/contacts")
async def get_chat_contacts(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Suhbat boshlash uchun kontaktlar ro'yxati.

    Ota-ona → o'z bolalari guruhining pedagoglari
    Pedagog → guruhlaridagi bolalarning ota-onalari
    """
    if current_user.role == UserRole.PARENT:
        children_result = await db.execute(
            select(Child).where(Child.parent_id == current_user.id)
        )
        children = children_result.scalars().all()
        group_ids = [c.group_id for c in children if c.group_id]
        if not group_ids:
            return []
        teachers_result = await db.execute(
            select(User)
            .join(Group, Group.teacher_id == User.id)
            .where(Group.id.in_(group_ids))
            .distinct()
        )
        contacts = teachers_result.scalars().all()

    elif current_user.role == UserRole.TEACHER:
        groups_result = await db.execute(
            select(Group).where(Group.teacher_id == current_user.id)
        )
        groups = groups_result.scalars().all()
        group_ids = [g.id for g in groups]
        if not group_ids:
            return []
        parents_result = await db.execute(
            select(User)
            .join(Child, Child.parent_id == User.id)
            .where(Child.group_id.in_(group_ids))
            .distinct()
        )
        contacts = parents_result.scalars().all()

    else:
        return []

    return [
        {"id": str(u.id), "full_name": u.full_name, "role": u.role.value}
        for u in contacts
        if u.id != current_user.id
    ]


# ============ WEBSOCKET ============

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
):
    """WebSocket ulanishi.
    
    Frontend so'rov: ws://server/api/v1/chat/ws?token=<JWT>
    
    Xabar formati (kiruvchi):
    {
        "action": "send",
        "receiver_id": "uuid",
        "content": "Salom!"
    }
    
    Xabar formati (chiquvchi):
    {
        "type": "new_message",
        "message": {...}
    }
    """
    # Token orqali user aniqlash
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        await websocket.close(code=1008, reason="Invalid token")
        return

    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, KeyError):
        await websocket.close(code=1008, reason="Invalid token")
        return

    await manager.connect(user_id, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action")

            if action == "send":
                # Xabarni DB ga saqlash va qabul qiluvchiga yuborish
                async with AsyncSessionLocal() as db:
                    try:
                        receiver_id = uuid.UUID(data["receiver_id"])
                    except (ValueError, KeyError):
                        await websocket.send_json({"type": "error", "message": "Invalid receiver_id"})
                        continue

                    msg = Message(
                        sender_id=user_id,
                        receiver_id=receiver_id,
                        content=data.get("content", ""),
                        message_type=MessageType(data.get("message_type", "text")),
                        file_url=data.get("file_url"),
                    )
                    db.add(msg)
                    await db.commit()
                    await db.refresh(msg)

                    payload_out = {
                        "type": "new_message",
                        "message": {
                            "id": str(msg.id),
                            "sender_id": str(msg.sender_id),
                            "receiver_id": str(msg.receiver_id),
                            "content": msg.content,
                            "message_type": msg.message_type.value,
                            "file_url": msg.file_url,
                            "is_read": False,
                            "created_at": msg.created_at.isoformat(),
                        },
                    }
                    # Qabul qiluvchiga
                    await manager.send_to_user(receiver_id, payload_out)
                    # Yuboruvchiga (boshqa qurilmalari uchun)
                    await manager.send_to_user(user_id, payload_out)

            elif action == "typing":
                # Yozyapti indikatori
                try:
                    receiver_id = uuid.UUID(data["receiver_id"])
                except (ValueError, KeyError):
                    continue
                await manager.send_to_user(
                    receiver_id,
                    {"type": "typing", "user_id": str(user_id)},
                )

            elif action == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
    except Exception as e:
        print(f"WebSocket xato: {e}")
        manager.disconnect(user_id, websocket)
