"""
Darslar, topshiriqlar, natijalar va kompetensiyalar.
"""
import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import String, Integer, ForeignKey, DateTime, Enum as SQLEnum, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class LessonCategory(str, Enum):
    LETTERS = "letters"
    NUMBERS = "numbers"
    COLORS = "colors"
    SHAPES = "shapes"
    MEMORY = "memory"
    PUZZLE = "puzzle"
    STORY = "story"
    DRAWING = "drawing"


class Lesson(Base):
    """Dars/o'yin - tayyor kontent (administrator yuklaydi)."""
    __tablename__ = "lessons"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[LessonCategory] = mapped_column(SQLEnum(LessonCategory), nullable=False, index=True)
    age_group: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    difficulty: Mapped[int] = mapped_column(Integer, default=1)  # 1-5

    # O'yin konfiguratsiyasi (JSON)
    # Misol: {"letters": ["A","B","C"], "audio_url": "...", "images": [...]}
    content: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)

    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Aloqalar
    assignments = relationship("Assignment", back_populates="lesson")
    progress_records = relationship("Progress", back_populates="lesson")


class Assignment(Base):
    """Pedagog tomonidan guruhga berilgan topshiriq."""
    __tablename__ = "assignments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    teacher_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE")
    )
    group_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("groups.id", ondelete="CASCADE")
    )
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("lessons.id", ondelete="CASCADE")
    )

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Aloqalar
    group = relationship("Group", back_populates="assignments")
    lesson = relationship("Lesson", back_populates="assignments")


class Progress(Base):
    """Bolaning har bir darsdagi natijasi."""
    __tablename__ = "progress"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True
    )
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("lessons.id", ondelete="CASCADE")
    )

    score: Mapped[int] = mapped_column(Integer, default=0)  # 0-100
    stars: Mapped[int] = mapped_column(Integer, default=0)  # 0-3
    time_spent_seconds: Mapped[int] = mapped_column(Integer, default=0)
    attempts: Mapped[int] = mapped_column(Integer, default=1)
    is_completed: Mapped[bool] = mapped_column(default=False)

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Aloqalar
    child = relationship("Child", back_populates="progress_records")
    lesson = relationship("Lesson", back_populates="progress_records")


class CompetencyType(str, Enum):
    SPEECH = "speech"           # Nutq
    ATTENTION = "attention"     # Diqqat
    MEMORY = "memory"           # Xotira
    MOTOR = "motor"             # Mayda motorika
    SOCIAL = "social"           # Ijtimoiy
    LOGIC = "logic"             # Mantiq


class Competency(Base):
    """Bolaning kompetensiyalar bo'yicha baholanishi (pedagog tomonidan)."""
    __tablename__ = "competencies"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True
    )
    competency_type: Mapped[CompetencyType] = mapped_column(SQLEnum(CompetencyType), nullable=False)
    level: Mapped[int] = mapped_column(Integer, default=1)  # 1-10
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Aloqalar
    child = relationship("Child", back_populates="competencies")
