"""
Ilova konfiguratsiyasi. Barcha sozlamalar .env faylidan o'qiladi.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Application
    APP_NAME: str = "Kichkintoy Connect"
    APP_ENV: str = "production"
    DEBUG: bool = False
    SECRET_KEY: str = "change-me"

    # Admin (birinchi ishga tushirishda yaratiladi)
    ADMIN_EMAIL: str = "admin"
    ADMIN_PASSWORD: str = "admin321"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://kichkintoy:kichkintoy@localhost:5432/kichkintoy_db"

    # JWT
    JWT_SECRET_KEY: str = "change-me-jwt"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:8000"]

    # MinIO
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_BUCKET: str = "kichkintoy-files"
    MINIO_SECURE: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
