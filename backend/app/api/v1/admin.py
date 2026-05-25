"""
Admin endpointlari: statistika, foydalanuvchilarni boshqarish.
Faqat admin roli uchun.
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from pydantic import BaseModel, Field
from datetime import datetime, date

from app.core.database import get_db
from app.core.security import hash_password
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.lesson import Lesson
from app.models.content import Story, Recommendation
from app.dependencies import require_admin


router = APIRouter(prefix="/admin", tags=["Admin"])


class UserAdminResponse(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str | None
    phone: str | None
    role: str
    is_active: bool
    created_at: datetime
    password_plain: str | None = None

    class Config:
        from_attributes = True


class AdminStatsResponse(BaseModel):
    total_users: int
    total_parents: int
    total_teachers: int
    total_children: int
    total_lessons: int
    total_stories: int
    total_recommendations: int
    total_groups: int


@router.get("/stats", response_model=AdminStatsResponse)
async def get_admin_stats(
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Tizim statistikasi."""
    users_result = await db.execute(
        select(User.role, func.count(User.id).label("cnt"))
        .where(User.role != UserRole.ADMIN)
        .group_by(User.role)
    )
    role_counts = {row.role: row.cnt for row in users_result}

    lessons_count = (await db.execute(select(func.count(Lesson.id)))).scalar() or 0
    stories_count = (await db.execute(select(func.count(Story.id)))).scalar() or 0
    recs_count = (await db.execute(select(func.count(Recommendation.id)))).scalar() or 0
    groups_count = (await db.execute(select(func.count(Group.id)))).scalar() or 0

    return AdminStatsResponse(
        total_users=sum(role_counts.values()),
        total_parents=role_counts.get(UserRole.PARENT, 0),
        total_teachers=role_counts.get(UserRole.TEACHER, 0),
        total_children=role_counts.get(UserRole.CHILD, 0),
        total_lessons=lessons_count,
        total_stories=stories_count,
        total_recommendations=recs_count,
        total_groups=groups_count,
    )


@router.get("/users", response_model=list[UserAdminResponse])
async def get_all_users(
    role: UserRole | None = None,
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Barcha foydalanuvchilar ro'yxati."""
    q = select(User).where(User.role != UserRole.ADMIN)
    if role is not None:
        q = q.where(User.role == role)
    q = q.order_by(User.role, User.created_at.desc())
    result = await db.execute(q)
    return result.scalars().all()


@router.patch("/users/{user_id}/toggle", response_model=UserAdminResponse)
async def toggle_user_active(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Foydalanuvchini faollashtirish / bloklash."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    if user.role == UserRole.ADMIN:
        raise HTTPException(403, "Admin bloklash mumkin emas")
    user.is_active = not user.is_active
    await db.flush()
    await db.refresh(user)
    return user


# ============ CREATE USER ============

class AdminCreateUserRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    role: UserRole
    phone: str | None = None
    email: str | None = None
    password: str = Field(..., min_length=4)


class AdminCreateChildRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    birth_date: date
    password: str = Field(..., min_length=4)
    parent_id: uuid.UUID
    nickname: str | None = None


class ChildAdminResponse(BaseModel):
    id: uuid.UUID
    full_name: str
    login: str
    age_group: int
    is_active: bool


@router.post("/users", response_model=UserAdminResponse, status_code=201)
async def admin_create_user(
    data: AdminCreateUserRequest,
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Yangi foydalanuvchi yaratish (ota-ona, pedagog, admin)."""
    if data.role == UserRole.CHILD:
        raise HTTPException(400, "Bola yaratish uchun /admin/children endpointidan foydalaning")
    if not data.phone and not data.email:
        raise HTTPException(400, "Telefon yoki email kerak")

    # Duplicate tekshiruvi
    if data.phone:
        ex = await db.execute(select(User).where(User.phone == data.phone))
        if ex.scalar_one_or_none():
            raise HTTPException(400, "Bu telefon raqam allaqachon ro'yxatdan o'tgan")
    if data.email:
        ex = await db.execute(select(User).where(User.email == data.email))
        if ex.scalar_one_or_none():
            raise HTTPException(400, "Bu email allaqachon ro'yxatdan o'tgan")

    user = User(
        phone=data.phone,
        email=data.email,
        password_hash=hash_password(data.password),
        password_plain=data.password,
        full_name=data.full_name,
        role=data.role,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/children", response_model=ChildAdminResponse, status_code=201)
async def admin_create_child(
    data: AdminCreateChildRequest,
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Yangi bola yaratish (ota-ona belgilanadi)."""
    # Ota-ona mavjudligini tekshirish
    parent_result = await db.execute(
        select(User).where(User.id == data.parent_id, User.role == UserRole.PARENT)
    )
    if not parent_result.scalar_one_or_none():
        raise HTTPException(404, "Ota-ona topilmadi")

    # Yoshni hisoblash
    today = date.today()
    age = today.year - data.birth_date.year - (
        (today.month, today.day) < (data.birth_date.month, data.birth_date.day)
    )
    if age < 2 or age > 10:
        raise HTTPException(400, f"Bola yoshi 2-10 oralig'ida bo'lishi kerak (hozir: {age})")

    # Login yaratish
    child_login = data.full_name.lower().split()[0][:20]
    ex = await db.execute(select(User).where(User.phone == child_login))
    if ex.scalar_one_or_none():
        child_login = f"{child_login}_{str(uuid.uuid4())[:4]}"

    child_user = User(
        phone=child_login,
        password_hash=hash_password(data.password),
        password_plain=data.password,
        full_name=data.full_name,
        role=UserRole.CHILD,
    )
    db.add(child_user)
    await db.flush()

    child = Child(
        user_id=child_user.id,
        parent_id=data.parent_id,
        birth_date=data.birth_date,
        age_group=age,
        nickname=data.nickname,
    )
    db.add(child)
    await db.flush()

    return ChildAdminResponse(
        id=child_user.id,
        full_name=data.full_name,
        login=child_login,
        age_group=age,
        is_active=True,
    )


@router.delete("/users/{user_id}", status_code=204)
async def admin_delete_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _=Depends(require_admin),
):
    """Foydalanuvchini o'chirish."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    if user.role == UserRole.ADMIN:
        raise HTTPException(403, "Admin o'chirilmaydi")

    if user.role == UserRole.PARENT:
        ch = await db.execute(select(Child).where(Child.parent_id == user_id))
        if ch.scalars().first():
            raise HTTPException(400, "Avval ota-onaning bolalarini o'chiring")

    if user.role == UserRole.TEACHER:
        gr = await db.execute(select(Group).where(Group.teacher_id == user_id))
        if gr.scalars().first():
            raise HTTPException(400, "Avval pedagogning guruhlarini o'chiring")

    if user.role == UserRole.CHILD:
        ch = await db.execute(select(Child).where(Child.user_id == user_id))
        child = ch.scalar_one_or_none()
        if child:
            await db.delete(child)

    await db.delete(user)
