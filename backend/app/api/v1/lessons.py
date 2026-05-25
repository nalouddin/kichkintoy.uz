"""
Darslar va o'yinlar endpointlari.
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from datetime import datetime

from app.core.database import get_db
from app.models.lesson import Lesson, Progress, LessonCategory
from app.models.child import Child
from app.models.user import User, UserRole
from app.dependencies import get_current_user, require_teacher_or_admin


router = APIRouter(prefix="/lessons", tags=["Darslar"])


class LessonResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    category: LessonCategory
    age_group: int
    difficulty: int
    content: dict
    thumbnail_url: str | None
    order: int

    class Config:
        from_attributes = True


class ProgressSubmit(BaseModel):
    """Bola o'yinni tugatgandan keyin natijani yuboradi."""
    child_id: uuid.UUID
    lesson_id: uuid.UUID
    score: int  # 0-100
    time_spent_seconds: int
    stars: int = 0  # 0-3


class ProgressResponse(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    lesson_id: uuid.UUID
    score: int
    stars: int
    time_spent_seconds: int
    attempts: int
    is_completed: bool
    completed_at: datetime | None

    class Config:
        from_attributes = True


@router.get("/", response_model=list[LessonResponse])
async def list_lessons(
    age_group: int | None = Query(None, ge=3, le=7),
    category: LessonCategory | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mavjud darslar ro'yxatini olish (yosh va kategoriya bo'yicha filtr)."""
    query = select(Lesson).where(Lesson.is_active == True)

    if age_group is not None:
        query = query.where(Lesson.age_group == age_group)
    if category is not None:
        query = query.where(Lesson.category == category)

    query = query.order_by(Lesson.order)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{lesson_id}", response_model=LessonResponse)
async def get_lesson(
    lesson_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bitta dars ma'lumotini olish."""
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Dars topilmadi")
    return lesson


@router.post("/progress", response_model=ProgressResponse, status_code=201)
async def submit_progress(
    data: ProgressSubmit,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bola o'yin natijasini saqlash.
    
    Bola yoki ota-ona o'z bolasi uchun natija yuborishi mumkin.
    """
    # Bolani topish va ruxsatni tekshirish
    child_result = await db.execute(select(Child).where(Child.id == data.child_id))
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="Bola topilmadi")

    # Faqat o'zi yoki uning ota-onasi natija yubora oladi
    is_self = current_user.id == child.user_id
    is_parent = current_user.id == child.parent_id
    if not (is_self or is_parent or current_user.role in (UserRole.ADMIN, UserRole.TEACHER)):
        raise HTTPException(status_code=403, detail="Bu bola uchun natija yuborib bo'lmaydi")

    # Darsni tekshirish
    lesson_result = await db.execute(select(Lesson).where(Lesson.id == data.lesson_id))
    lesson = lesson_result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Dars topilmadi")

    # Avvalgi urinish mavjudmi tekshirish
    existing_result = await db.execute(
        select(Progress).where(
            Progress.child_id == data.child_id,
            Progress.lesson_id == data.lesson_id,
        )
    )
    existing = existing_result.scalar_one_or_none()

    if existing:
        # Yangilash (eng yaxshi natijani saqlash)
        existing.attempts += 1
        existing.time_spent_seconds += data.time_spent_seconds
        if data.score > existing.score:
            existing.score = data.score
            existing.stars = max(existing.stars, data.stars)
        existing.is_completed = data.score >= 60
        if existing.is_completed and not existing.completed_at:
            existing.completed_at = datetime.utcnow()
        progress = existing
    else:
        progress = Progress(
            child_id=data.child_id,
            lesson_id=data.lesson_id,
            score=data.score,
            stars=data.stars,
            time_spent_seconds=data.time_spent_seconds,
            is_completed=data.score >= 60,
            completed_at=datetime.utcnow() if data.score >= 60 else None,
        )
        db.add(progress)

    # Bolaning umumiy yulduzlarini yangilash
    if data.stars > 0:
        child.total_stars += data.stars

    await db.flush()
    await db.refresh(progress)
    return progress


@router.get("/progress/child/{child_id}", response_model=list[ProgressResponse])
async def get_child_progress(
    child_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bolaning barcha natijalarini olish."""
    child_result = await db.execute(select(Child).where(Child.id == child_id))
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=404, detail="Bola topilmadi")

    # Ruxsat: bola o'zi, ota-onasi, pedagogi, yoki admin
    allowed = (
        current_user.id == child.user_id or
        current_user.id == child.parent_id or
        current_user.role in (UserRole.TEACHER, UserRole.ADMIN)
    )
    if not allowed:
        raise HTTPException(status_code=403, detail="Ruxsat yo'q")

    result = await db.execute(
        select(Progress)
        .where(Progress.child_id == child_id)
        .order_by(Progress.created_at.desc())
    )
    return result.scalars().all()


# ============ ADMIN: dars yaratish ============

class LessonCreate(BaseModel):
    title: str
    description: str | None = None
    category: LessonCategory
    age_group: int
    difficulty: int = 1
    content: dict
    thumbnail_url: str | None = None
    order: int = 0


@router.post("/", response_model=LessonResponse, status_code=201)
async def create_lesson(
    data: LessonCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher_or_admin),
):
    """Yangi dars yaratish (faqat pedagog/admin)."""
    lesson = Lesson(**data.model_dump())
    db.add(lesson)
    await db.flush()
    await db.refresh(lesson)
    return lesson


@router.delete("/{lesson_id}", status_code=204)
async def delete_lesson(
    lesson_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_teacher_or_admin),
):
    """Darsni o'chirish (faqat admin/pedagog)."""
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Dars topilmadi")
    await db.delete(lesson)
