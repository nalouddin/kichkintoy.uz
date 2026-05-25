"""
Autentifikatsiya uchun Pydantic sxemalar (so'rov va javob formatlari).
"""
import uuid
from datetime import date, datetime
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.models.user import UserRole


class UserRegister(BaseModel):
    """Yangi foydalanuvchini ro'yxatga olish."""
    email: EmailStr | None = None
    phone: str | None = Field(None, min_length=9, max_length=20)
    password: str = Field(..., min_length=6, max_length=100)
    full_name: str = Field(..., min_length=2, max_length=255)
    role: UserRole

    @field_validator("role")
    @classmethod
    def role_cannot_be_admin(cls, v: UserRole) -> UserRole:
        # Adminni faqat seed orqali yaratamiz, ro'yxatdan o'tishda emas
        if v == UserRole.ADMIN:
            raise ValueError("Admin rolida ro'yxatdan o'tib bo'lmaydi")
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone_or_email(cls, v, info):
        # Hech bo'lmaganda biri bo'lishi kerak
        if not v and not info.data.get("email"):
            raise ValueError("Email yoki telefon raqam kiritilishi shart")
        return v


class UserLogin(BaseModel):
    """Tizimga kirish (email yoki telefon)."""
    login: str  # email yoki telefon
    password: str


class Token(BaseModel):
    """JWT tokenlar javobi."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    """Foydalanuvchi ma'lumotlari (parolsiz)."""
    id: uuid.UUID
    email: str | None
    phone: str | None
    full_name: str
    role: UserRole
    avatar_url: str | None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ChildCreate(BaseModel):
    """Ota-ona o'z bolasini qo'shadi."""
    full_name: str = Field(..., min_length=2, max_length=255)
    birth_date: date
    nickname: str | None = None
    avatar_url: str | None = None

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
    birth_date: date
    age_group: int
    nickname: str | None
    total_stars: int

    class Config:
        from_attributes = True
