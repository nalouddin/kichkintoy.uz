"""
Alembic env.py — migratsiyalarni boshqaradi.
Barcha modellar shu yerda import qilinadi (autogenerate uchun).
"""
import os
import sys
from logging.config import fileConfig
from pathlib import Path

from sqlalchemy import engine_from_config, pool
from alembic import context

# Loyiha root'ini PYTHONPATH'ga qo'shamiz
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# Barcha modellarni import qilamiz (Base.metadata to'lib boradi)
from app.models import Base
from app.core.config import settings

config = context.config

# Database URL ni .env dan olib, sync versiyaga aylantiramiz
# (Alembic sync ishlaydi, asyncpg emas)
db_url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
config.set_main_option("sqlalchemy.url", db_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """SQL faylga yozish rejimi (DB ga ulanmasdan)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """To'g'ridan-to'g'ri DB bilan ulanish rejimi."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
