"""
Bolalar endpointlari: ota-ona bola qo'shadi, statistika oladi.
"""
import uuid
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from pydantic import BaseModel, Field, field_validator

from app.core.database import get_db
from app.core.security import hash_password
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.lesson import Lesson, Progress, Competency
from app.dependencies import get_current_user, require_parent, require_teacher_or_admin


router = APIRouter(prefix="/children", tags=["Bolalar"])


# ============ SCHEMAS ============

class ChildCreateRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    birth_date: date
    nickname: str | None = None
    password: str = Field(..., min_length=4, max_length=100)  # bola login uchun

    @field_validator("birth_date")
    @classmethod
    def validate_age(cls, v: date) -> date:
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        if age < 2 or age > 10:
            raise ValueError("Bola yoshi 2-10 oralig'ida bo'lishi kerak")
        return v


class ChildResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    parent_id: uuid.UUID
    group_id: uuid.UUID | None
    full_name: str
    nickname: str | None
    birth_date: date
    age_group: int
    total_stars: int
    avatar_url: str | None = None
    login: str | None = None  # email/phone bola login uchun

    class Config:
        from_attributes = True


class AssignGroupRequest(BaseModel):
    group_id: uuid.UUID | None = None


class ChildStatsResponse(BaseModel):
    """Bola umumiy statistikasi."""
    child_id: uuid.UUID
    total_lessons_completed: int
    total_stars: int
    total_time_minutes: int
    average_score: float
    streak_days: int  # ketma-ket kunlar
    by_category: dict  # {"letters": {"completed": 5, "avg_score": 85.5}, ...}
    weekly_activity: list  # [{"date": "2026-01-01", "lessons": 3, "stars": 6}, ...]


# ============ ENDPOINTS ============

@router.post("/", response_model=ChildResponse, status_code=201)
async def add_child(
    data: ChildCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_parent),
):
    """Ota-ona o'z bolasini qo'shadi.
    
    Bolaga avtomatik User akkaunt yaratiladi (login uchun).
    Login: ota-onaning telefoni + "_" + bola ismi
    """
    # Bola yoshini hisoblash
    today = date.today()
    age = today.year - data.birth_date.year - (
        (today.month, today.day) < (data.birth_date.month, data.birth_date.day)
    )

    # Bola uchun unique login yaratish (faqat bola ismi)
    child_login = data.full_name.lower().split()[0][:20]

    # Login uniqueligini tekshirish
    existing = await db.execute(
        select(User).where(User.phone == child_login)
    )
    if existing.scalar_one_or_none():
        # Agar duplicate bo'lsa - random suffix qo'shamiz
        child_login = f"{child_login}_{str(uuid.uuid4())[:4]}"

    # Bola User akkaunti
    child_user = User(
        phone=child_login,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        role=UserRole.CHILD,
    )
    db.add(child_user)
    await db.flush()

    # Child profile
    child = Child(
        user_id=child_user.id,
        parent_id=current_user.id,
        birth_date=data.birth_date,
        age_group=age,
        nickname=data.nickname,
    )
    db.add(child)
    await db.flush()
    await db.refresh(child)

    return ChildResponse(
        id=child.id,
        user_id=child.user_id,
        parent_id=child.parent_id,
        group_id=child.group_id,
        full_name=child_user.full_name,
        nickname=child.nickname,
        birth_date=child.birth_date,
        age_group=child.age_group,
        total_stars=child.total_stars,
        login=child_login,
    )


@router.get("/me", response_model=ChildResponse)
async def get_my_child_profile(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bolaning o'z profili (role=child bo'lganlar uchun)."""
    result = await db.execute(
        select(Child, User)
        .join(User, Child.user_id == User.id)
        .where(Child.user_id == current_user.id)
    )
    row = result.first()
    if not row:
        raise HTTPException(404, "Bola profili topilmadi")

    child, user = row
    return ChildResponse(
        id=child.id,
        user_id=child.user_id,
        parent_id=child.parent_id,
        group_id=child.group_id,
        full_name=user.full_name,
        nickname=child.nickname,
        birth_date=child.birth_date,
        age_group=child.age_group,
        total_stars=child.total_stars,
        login=user.phone,
    )


@router.get("/my", response_model=list[ChildResponse])
async def get_my_children(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_parent),
):
    """Ota-onaning barcha bolalari ro'yxati."""
    result = await db.execute(
        select(Child, User)
        .join(User, Child.user_id == User.id)
        .where(Child.parent_id == current_user.id)
    )
    rows = result.all()

    return [
        ChildResponse(
            id=child.id,
            user_id=child.user_id,
            parent_id=child.parent_id,
            group_id=child.group_id,
            full_name=user.full_name,
            nickname=child.nickname,
            birth_date=child.birth_date,
            age_group=child.age_group,
            total_stars=child.total_stars,
            login=user.phone,
        )
        for child, user in rows
    ]


@router.get("/{child_id}", response_model=ChildResponse)
async def get_child(
    child_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bitta bola ma'lumotini olish."""
    result = await db.execute(
        select(Child, User)
        .join(User, Child.user_id == User.id)
        .where(Child.id == child_id)
    )
    row = result.first()
    if not row:
        raise HTTPException(404, "Bola topilmadi")

    child, user = row

    # Ruxsat tekshiruvi
    allowed = (
        current_user.id == child.parent_id or
        current_user.id == child.user_id or
        current_user.role in (UserRole.TEACHER, UserRole.ADMIN)
    )
    if not allowed:
        raise HTTPException(403, "Ruxsat yo'q")

    return ChildResponse(
        id=child.id,
        user_id=child.user_id,
        parent_id=child.parent_id,
        group_id=child.group_id,
        full_name=user.full_name,
        nickname=child.nickname,
        birth_date=child.birth_date,
        age_group=child.age_group,
        total_stars=child.total_stars,
        login=user.phone,
    )


@router.get("/{child_id}/stats", response_model=ChildStatsResponse)
async def get_child_stats(
    child_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bola statistikasi: jami, kategoriya bo'yicha, haftalik faollik."""
    # Bola va ruxsat
    child_result = await db.execute(select(Child).where(Child.id == child_id))
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(404, "Bola topilmadi")

    allowed = (
        current_user.id == child.parent_id or
        current_user.id == child.user_id or
        current_user.role in (UserRole.TEACHER, UserRole.ADMIN)
    )
    if not allowed:
        raise HTTPException(403, "Ruxsat yo'q")

    # Umumiy statistika
    progress_result = await db.execute(
        select(
            func.count(Progress.id).label("total"),
            func.sum(Progress.time_spent_seconds).label("time"),
            func.avg(Progress.score).label("avg_score"),
        ).where(
            Progress.child_id == child_id,
            Progress.is_completed == True,
        )
    )
    stats = progress_result.first()

    # Kategoriya bo'yicha
    cat_result = await db.execute(
        select(
            Lesson.category,
            func.count(Progress.id).label("completed"),
            func.avg(Progress.score).label("avg"),
        )
        .join(Progress, Progress.lesson_id == Lesson.id)
        .where(Progress.child_id == child_id, Progress.is_completed == True)
        .group_by(Lesson.category)
    )
    by_category = {
        row.category.value: {
            "completed": row.completed,
            "avg_score": round(float(row.avg or 0), 1),
        }
        for row in cat_result
    }

    # Oxirgi 7 kun
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    weekly_result = await db.execute(
        select(
            func.date(Progress.completed_at).label("date"),
            func.count(Progress.id).label("lessons"),
            func.sum(Progress.stars).label("stars"),
        )
        .where(
            Progress.child_id == child_id,
            Progress.completed_at >= seven_days_ago,
            Progress.is_completed == True,
        )
        .group_by(func.date(Progress.completed_at))
        .order_by(func.date(Progress.completed_at))
    )
    weekly_activity = [
        {
            "date": row.date.isoformat() if row.date else None,
            "lessons": row.lessons,
            "stars": row.stars or 0,
        }
        for row in weekly_result
    ]

    # Streak (ketma-ket kunlar) — sodda hisoblash
    streak = 0
    if weekly_activity:
        today = date.today()
        for i in range(7):
            check_date = today - timedelta(days=i)
            found = any(
                wa["date"] == check_date.isoformat() for wa in weekly_activity
            )
            if found:
                streak += 1
            else:
                break

    return ChildStatsResponse(
        child_id=child_id,
        total_lessons_completed=stats.total or 0,
        total_stars=child.total_stars,
        total_time_minutes=int((stats.time or 0) / 60),
        average_score=round(float(stats.avg_score or 0), 1),
        streak_days=streak,
        by_category=by_category,
        weekly_activity=weekly_activity,
    )


@router.patch("/{child_id}/group", response_model=ChildResponse)
async def assign_child_to_group(
    child_id: uuid.UUID,
    data: AssignGroupRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Ota-ona yoki pedagog bolani guruhga biriktiradi yoki guruhdan chiqaradi."""
    if current_user.role not in (UserRole.PARENT, UserRole.TEACHER, UserRole.ADMIN):
        raise HTTPException(403, "Ruxsat yo'q")
    result = await db.execute(
        select(Child, User)
        .join(User, Child.user_id == User.id)
        .where(Child.id == child_id)
    )
    row = result.first()
    if not row:
        raise HTTPException(404, "Bola topilmadi")
    child, child_user = row
    if child.parent_id != current_user.id and current_user.role not in (UserRole.TEACHER, UserRole.ADMIN):
        raise HTTPException(403, "Bu bola sizniki emas")

    if data.group_id is not None:
        from app.models.child import Group
        group_result = await db.execute(select(Group).where(Group.id == data.group_id))
        if not group_result.scalar_one_or_none():
            raise HTTPException(404, "Guruh topilmadi")

    child.group_id = data.group_id
    await db.flush()
    await db.refresh(child)

    return ChildResponse(
        id=child.id,
        user_id=child.user_id,
        parent_id=child.parent_id,
        group_id=child.group_id,
        full_name=child_user.full_name,
        nickname=child.nickname,
        birth_date=child.birth_date,
        age_group=child.age_group,
        total_stars=child.total_stars,
        login=child_user.phone,
    )


@router.delete("/{child_id}", status_code=204)
async def remove_child(
    child_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bolani o'chirish (ota-ona yoki pedagog/admin)."""
    if current_user.role not in (UserRole.PARENT, UserRole.TEACHER, UserRole.ADMIN):
        raise HTTPException(403, "Ruxsat yo'q")
    result = await db.execute(select(Child).where(Child.id == child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(404, "Bola topilmadi")
    if child.parent_id != current_user.id and current_user.role not in (UserRole.TEACHER, UserRole.ADMIN):
        raise HTTPException(403, "Faqat bolaning ota-onasi o'chira oladi")

    # Bola User akkauntini ham o'chiramiz (cascade)
    user_result = await db.execute(select(User).where(User.id == child.user_id))
    user = user_result.scalar_one_or_none()
    if user:
        await db.delete(user)
    await db.delete(child)
    await db.flush()
