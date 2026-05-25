"""
Bola profili - har bir bola ota-ona va guruhga bog'lanadi.
"""
import uuid
from datetime import date, datetime
from sqlalchemy import String, Date, Integer, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Child(Base):
    __tablename__ = "children"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    parent_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE")
    )
    group_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("groups.id", ondelete="SET NULL"), nullable=True
    )

    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    age_group: Mapped[int] = mapped_column(Integer, nullable=False)  # 3-7
    nickname: Mapped[str | None] = mapped_column(String(100), nullable=True)
    total_stars: Mapped[int] = mapped_column(Integer, default=0)  # rag'batlantirish

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Aloqalar
    user = relationship("User", back_populates="child_profile", foreign_keys=[user_id])
    parent = relationship("User", foreign_keys=[parent_id])
    group = relationship("Group", back_populates="children")
    progress_records = relationship("Progress", back_populates="child", cascade="all, delete-orphan")
    competencies = relationship("Competency", back_populates="child", cascade="all, delete-orphan")


class Group(Base):
    """Pedagog guruhi - bir nechta bola bir pedagogga biriktiriladi."""
    __tablename__ = "groups"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    teacher_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE")
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    age_group: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Aloqalar
    teacher = relationship("User", back_populates="teacher_groups")
    children = relationship("Child", back_populates="group")
    assignments = relationship("Assignment", back_populates="group", cascade="all, delete-orphan")
