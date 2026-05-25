"""
Kontent modellari: ertaklar, she'rlar, tavsiyalar.
"""
import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import String, Integer, DateTime, Enum as SQLEnum, Text, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class StoryCategory(str, Enum):
    STORY = "story"   # Ertak
    POEM = "poem"     # She'r
    SONG = "song"     # Qo'shiq


class RecommendationCategory(str, Enum):
    PARENT = "parent"           # Ota-ona uchun maslahat
    TEACHER = "teacher"         # Pedagog uchun maslahat
    PSYCHOLOGY = "psychology"   # Psixolog maslahati
    DEVELOPMENT = "development" # Rivojlanish bo'yicha


class Story(Base):
    """Ertak, she'r yoki qo'shiq."""
    __tablename__ = "stories"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    audio_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    age_group: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    category: Mapped[StoryCategory] = mapped_column(
        SQLEnum(StoryCategory, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        index=True,
    )
    author: Mapped[str | None] = mapped_column(String(200), nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)
    order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class Recommendation(Base):
    """Psixolog va mutaxassislar tavsiyasi."""
    __tablename__ = "recommendations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[RecommendationCategory] = mapped_column(
        SQLEnum(RecommendationCategory, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        index=True,
    )
    age_group: Mapped[int | None] = mapped_column(Integer, nullable=True)
    author: Mapped[str | None] = mapped_column(String(200), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
