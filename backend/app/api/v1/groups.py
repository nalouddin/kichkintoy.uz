"""
Pedagog modullari: guruh, topshiriq, monitoring.
"""
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.models.user import User, UserRole
from app.models.child import Child, Group
from app.models.lesson import Lesson, Assignment, Progress
from app.dependencies import get_current_user, require_teacher, require_teacher_or_admin


router = APIRouter(prefix="/groups", tags=["Pedagog: guruhlar"])


# ============ SCHEMAS ============

class GroupCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    age_group: int = Field(..., ge=2, le=10)
    description: str | None = None


class GroupResponse(BaseModel):
    id: uuid.UUID
    teacher_id: uuid.UUID
    name: str
    age_group: int
    description: str | None
    children_count: int = 0

    class Config:
        from_attributes = True


class AssignmentCreate(BaseModel):
    group_id: uuid.UUID
    lesson_id: uuid.UUID
    title: str = Field(..., min_length=2, max_length=200)
    instructions: str | None = None
    due_date: datetime | None = None


class AssignmentResponse(BaseModel):
    id: uuid.UUID
    teacher_id: uuid.UUID
    group_id: uuid.UUID
    lesson_id: uuid.UUID
    title: str
    instructions: str | None
    due_date: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True


class ChildInGroupResponse(BaseModel):
    """Pedagog uchun guruhdagi bola ma'lumoti."""
    id: uuid.UUID
    full_name: str
    age_group: int
    total_stars: int
    lessons_completed: int
    avg_score: float


class AddChildToGroup(BaseModel):
    child_id: uuid.UUID


# ============ GROUPS ============

@router.get("/", response_model=list[GroupResponse])
async def get_all_groups(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Barcha guruhlar ro'yxati (ota-ona farzandini biriktirish uchun)."""
    result = await db.execute(
        select(
            Group,
            func.count(Child.id).label("children_count"),
        )
        .outerjoin(Child, Child.group_id == Group.id)
        .group_by(Group.id)
        .order_by(Group.age_group, Group.name)
    )
    return [
        GroupResponse(
            id=group.id,
            teacher_id=group.teacher_id,
            name=group.name,
            age_group=group.age_group,
            description=group.description,
            children_count=count,
        )
        for group, count in result.all()
    ]


@router.post("/", response_model=GroupResponse, status_code=201)
async def create_group(
    data: GroupCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Yangi guruh yaratish."""
    group = Group(
        teacher_id=current_user.id,
        name=data.name,
        age_group=data.age_group,
        description=data.description,
    )
    db.add(group)
    await db.flush()
    await db.refresh(group)
    return GroupResponse(
        id=group.id,
        teacher_id=group.teacher_id,
        name=group.name,
        age_group=group.age_group,
        description=group.description,
        children_count=0,
    )


@router.get("/my", response_model=list[GroupResponse])
async def get_my_groups(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Pedagogning barcha guruhlari."""
    result = await db.execute(
        select(
            Group,
            func.count(Child.id).label("children_count"),
        )
        .outerjoin(Child, Child.group_id == Group.id)
        .where(Group.teacher_id == current_user.id)
        .group_by(Group.id)
    )
    return [
        GroupResponse(
            id=group.id,
            teacher_id=group.teacher_id,
            name=group.name,
            age_group=group.age_group,
            description=group.description,
            children_count=count,
        )
        for group, count in result.all()
    ]


@router.get("/{group_id}/children", response_model=list[ChildInGroupResponse])
async def get_group_children(
    group_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Guruhdagi bolalar va ularning statistikasi."""
    # Guruh egasi tekshirish
    group_result = await db.execute(select(Group).where(Group.id == group_id))
    group = group_result.scalar_one_or_none()
    if not group:
        raise HTTPException(404, "Guruh topilmadi")

    # Guruhdagi bolalar
    result = await db.execute(
        select(
            Child.id,
            User.full_name,
            Child.age_group,
            Child.total_stars,
            func.count(Progress.id).filter(Progress.is_completed == True).label("completed"),
            func.avg(Progress.score).label("avg_score"),
        )
        .join(User, Child.user_id == User.id)
        .outerjoin(Progress, Progress.child_id == Child.id)
        .where(Child.group_id == group_id)
        .group_by(Child.id, User.full_name, Child.age_group, Child.total_stars)
    )

    return [
        ChildInGroupResponse(
            id=row.id,
            full_name=row.full_name,
            age_group=row.age_group,
            total_stars=row.total_stars,
            lessons_completed=row.completed or 0,
            avg_score=round(float(row.avg_score or 0), 1),
        )
        for row in result
    ]


@router.post("/{group_id}/children", status_code=200)
async def add_child_to_group(
    group_id: uuid.UUID,
    data: AddChildToGroup,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Bolani guruhga qo'shish."""
    group_result = await db.execute(select(Group).where(Group.id == group_id))
    group = group_result.scalar_one_or_none()
    if not group:
        raise HTTPException(404, "Guruh topilmadi")

    child_result = await db.execute(select(Child).where(Child.id == data.child_id))
    child = child_result.scalar_one_or_none()
    if not child:
        raise HTTPException(404, "Bola topilmadi")

    child.group_id = group_id
    await db.flush()
    return {"message": "Bola guruhga qo'shildi"}


@router.delete("/{group_id}", status_code=204)
async def delete_group(
    group_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Guruhni o'chirish."""
    result = await db.execute(select(Group).where(Group.id == group_id))
    group = result.scalar_one_or_none()
    if not group:
        raise HTTPException(404, "Guruh topilmadi")
    await db.delete(group)


# ============ ASSIGNMENTS ============

assignments_router = APIRouter(prefix="/assignments", tags=["Pedagog: topshiriqlar"])


@assignments_router.post("/", response_model=AssignmentResponse, status_code=201)
async def create_assignment(
    data: AssignmentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher),
):
    """Guruhga topshiriq yuklash."""
    # Guruh va dars mavjudligini tekshirish
    group_result = await db.execute(select(Group).where(Group.id == data.group_id))
    group = group_result.scalar_one_or_none()
    if not group:
        raise HTTPException(404, "Guruh topilmadi")

    lesson_result = await db.execute(select(Lesson).where(Lesson.id == data.lesson_id))
    if not lesson_result.scalar_one_or_none():
        raise HTTPException(404, "Dars topilmadi")

    assignment = Assignment(
        teacher_id=current_user.id,
        group_id=data.group_id,
        lesson_id=data.lesson_id,
        title=data.title,
        instructions=data.instructions,
        due_date=data.due_date,
    )
    db.add(assignment)
    await db.flush()
    await db.refresh(assignment)
    return assignment


@assignments_router.get("/group/{group_id}", response_model=list[AssignmentResponse])
async def get_group_assignments(
    group_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Guruhdagi topshiriqlar."""
    result = await db.execute(
        select(Assignment)
        .where(Assignment.group_id == group_id)
        .order_by(Assignment.created_at.desc())
    )
    return result.scalars().all()


@assignments_router.get("/my", response_model=list[AssignmentResponse])
async def get_my_assignments(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bola uchun: o'zining guruhidagi topshiriqlar.
    Pedagog uchun: o'zi bergan topshiriqlar."""
    if current_user.role == UserRole.CHILD:
        # Bola guruhini topish
        child_result = await db.execute(
            select(Child).where(Child.user_id == current_user.id)
        )
        child = child_result.scalar_one_or_none()
        if not child or not child.group_id:
            return []
        result = await db.execute(
            select(Assignment)
            .where(Assignment.group_id == child.group_id)
            .order_by(Assignment.created_at.desc())
        )
    elif current_user.role in (UserRole.TEACHER, UserRole.ADMIN):
        result = await db.execute(
            select(Assignment)
            .where(Assignment.teacher_id == current_user.id)
            .order_by(Assignment.created_at.desc())
        )
    else:
        return []

    return result.scalars().all()
