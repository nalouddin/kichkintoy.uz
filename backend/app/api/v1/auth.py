"""
Autentifikatsiya endpointlari: ro'yxatdan o'tish, login, refresh.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from app.core.database import get_db
from app.core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token
)
from app.models.user import User
from app.schemas.auth import UserRegister, UserLogin, Token, UserResponse
from app.dependencies import get_current_user


router = APIRouter(prefix="/auth", tags=["Autentifikatsiya"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister, db: AsyncSession = Depends(get_db)) -> User:
    """Yangi foydalanuvchini ro'yxatga olish (ota-ona yoki pedagog)."""

    # Email yoki telefon allaqachon mavjudligini tekshirish
    conditions = []
    if data.email:
        conditions.append(User.email == data.email)
    if data.phone:
        conditions.append(User.phone == data.phone)

    if conditions:
        existing = await db.execute(select(User).where(or_(*conditions)))
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bu email yoki telefon raqami allaqachon ro'yxatdan o'tgan"
            )

    new_user = User(
        email=data.email,
        phone=data.phone,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        role=data.role,
    )
    db.add(new_user)
    await db.flush()
    await db.refresh(new_user)
    return new_user


@router.post("/login", response_model=Token)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)) -> Token:
    """Tizimga kirish - email yoki telefon + parol."""

    # Login email yoki telefon bo'lishi mumkin
    result = await db.execute(
        select(User).where(
            or_(User.email == data.login, User.phone == data.login)
        )
    )
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login yoki parol xato"
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akkaunt faollashtirilmagan"
        )

    return Token(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db)
) -> Token:
    """Yangi access token olish refresh token orqali."""
    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token yaroqsiz"
        )

    user_id = payload.get("sub")
    return Token(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)) -> User:
    """Joriy foydalanuvchi ma'lumotlari."""
    return current_user
