"""
Kontent API: ertaklar, she'rlar, tavsiyalar.
GET - hamma, POST/PUT/DELETE - faqat admin.
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.models.content import Story, Recommendation, StoryCategory, RecommendationCategory
from app.models.user import User
from app.dependencies import get_current_user, require_admin


router = APIRouter(prefix="/content", tags=["Kontent"])


# ============ SCHEMAS ============

class StoryCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    description: str | None = Field(None, max_length=500)
    content: str = Field(..., min_length=10)
    audio_url: str | None = None
    thumbnail_url: str | None = None
    age_group: int = Field(..., ge=2, le=10)
    category: StoryCategory
    author: str | None = None
    duration_seconds: int = 0
    order: int = 0


class StoryUpdate(BaseModel):
    title: str | None = Field(None, min_length=2, max_length=200)
    description: str | None = None
    content: str | None = Field(None, min_length=10)
    audio_url: str | None = None
    thumbnail_url: str | None = None
    age_group: int | None = Field(None, ge=2, le=10)
    category: StoryCategory | None = None
    author: str | None = None
    duration_seconds: int | None = None
    order: int | None = None
    is_active: bool | None = None


class StoryResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    content: str
    audio_url: str | None
    thumbnail_url: str | None
    age_group: int
    category: str
    author: str | None
    duration_seconds: int
    order: int
    is_active: bool

    class Config:
        from_attributes = True


class RecommendationCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    content: str = Field(..., min_length=10)
    category: RecommendationCategory
    age_group: int | None = Field(None, ge=2, le=10)
    author: str | None = None


class RecommendationUpdate(BaseModel):
    title: str | None = Field(None, min_length=2, max_length=200)
    content: str | None = Field(None, min_length=10)
    category: RecommendationCategory | None = None
    age_group: int | None = None
    author: str | None = None
    is_active: bool | None = None


class RecommendationResponse(BaseModel):
    id: uuid.UUID
    title: str
    content: str
    category: str
    age_group: int | None
    author: str | None
    is_active: bool

    class Config:
        from_attributes = True


# ============ STORIES ============

@router.get("/stories/", response_model=list[StoryResponse])
async def get_stories(
    age_group: int | None = None,
    category: StoryCategory | None = None,
    include_inactive: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Ertaklar ro'yxati. Admin inactive larni ham ko'ra oladi."""
    from app.models.user import UserRole
    q = select(Story).order_by(Story.order, Story.created_at)
    if not include_inactive or current_user.role not in (UserRole.ADMIN, UserRole.TEACHER):
        q = q.where(Story.is_active == True)
    if age_group is not None:
        q = q.where(Story.age_group <= age_group)
    if category is not None:
        q = q.where(Story.category == category)
    result = await db.execute(q)
    return result.scalars().all()


@router.get("/stories/{story_id}", response_model=StoryResponse)
async def get_story(
    story_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """Bitta ertak."""
    result = await db.execute(select(Story).where(Story.id == story_id))
    story = result.scalar_one_or_none()
    if not story:
        raise HTTPException(404, "Ertak topilmadi")
    return story


@router.post("/stories/", response_model=StoryResponse, status_code=201)
async def create_story(
    data: StoryCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Yangi ertak yaratish (faqat admin)."""
    story = Story(**data.model_dump())
    db.add(story)
    await db.flush()
    await db.refresh(story)
    return story


@router.put("/stories/{story_id}", response_model=StoryResponse)
async def update_story(
    story_id: uuid.UUID,
    data: StoryUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Ertakni yangilash (faqat admin)."""
    result = await db.execute(select(Story).where(Story.id == story_id))
    story = result.scalar_one_or_none()
    if not story:
        raise HTTPException(404, "Ertak topilmadi")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(story, field, value)
    await db.flush()
    await db.refresh(story)
    return story


@router.delete("/stories/{story_id}", status_code=204)
async def delete_story(
    story_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Ertakni o'chirish (faqat admin)."""
    result = await db.execute(select(Story).where(Story.id == story_id))
    story = result.scalar_one_or_none()
    if not story:
        raise HTTPException(404, "Ertak topilmadi")
    await db.delete(story)


# ============ RECOMMENDATIONS ============

@router.get("/recommendations/", response_model=list[RecommendationResponse])
async def get_recommendations(
    category: RecommendationCategory | None = None,
    age_group: int | None = None,
    include_inactive: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Tavsiyalar ro'yxati."""
    from app.models.user import UserRole
    q = select(Recommendation).order_by(Recommendation.created_at)
    if not include_inactive or current_user.role not in (UserRole.ADMIN, UserRole.TEACHER):
        q = q.where(Recommendation.is_active == True)
    if category is not None:
        q = q.where(Recommendation.category == category)
    if age_group is not None:
        q = q.where(
            or_(
                Recommendation.age_group == age_group,
                Recommendation.age_group == None,
            )
        )
    result = await db.execute(q)
    return result.scalars().all()


@router.post("/recommendations/", response_model=RecommendationResponse, status_code=201)
async def create_recommendation(
    data: RecommendationCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Yangi tavsiya yaratish (faqat admin)."""
    rec = Recommendation(**data.model_dump())
    db.add(rec)
    await db.flush()
    await db.refresh(rec)
    return rec


@router.put("/recommendations/{rec_id}", response_model=RecommendationResponse)
async def update_recommendation(
    rec_id: uuid.UUID,
    data: RecommendationUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Tavsiyani yangilash (faqat admin)."""
    result = await db.execute(select(Recommendation).where(Recommendation.id == rec_id))
    rec = result.scalar_one_or_none()
    if not rec:
        raise HTTPException(404, "Tavsiya topilmadi")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(rec, field, value)
    await db.flush()
    await db.refresh(rec)
    return rec


@router.delete("/recommendations/{rec_id}", status_code=204)
async def delete_recommendation(
    rec_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Tavsiyani o'chirish (faqat admin)."""
    result = await db.execute(select(Recommendation).where(Recommendation.id == rec_id))
    rec = result.scalar_one_or_none()
    if not rec:
        raise HTTPException(404, "Tavsiya topilmadi")
    await db.delete(rec)
