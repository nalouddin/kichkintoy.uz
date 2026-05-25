"""
Barcha modellarni bir joydan import qilish uchun.
Alembic migratsiyalar ham shu yerdan modellarni topadi.
"""
from app.core.database import Base
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.lesson import (
    Lesson, Assignment, Progress, Competency,
    LessonCategory, CompetencyType
)
from app.models.message import Message, MessageType
from app.models.content import Story, Recommendation, StoryCategory, RecommendationCategory

__all__ = [
    "Base",
    "User", "UserRole",
    "Child", "Group",
    "Lesson", "Assignment", "Progress", "Competency",
    "LessonCategory", "CompetencyType",
    "Message", "MessageType",
    "Story", "Recommendation", "StoryCategory", "RecommendationCategory",
]
