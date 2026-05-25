"""extend phone column to 100 chars

Revision ID: a2b3c4d5e6f7
Revises: 1cea2dfda9d2
Create Date: 2026-05-23 10:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'a2b3c4d5e6f7'
down_revision: Union[str, None] = '1cea2dfda9d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column('users', 'phone',
                    existing_type=sa.String(length=20),
                    type_=sa.String(length=100),
                    existing_nullable=True)


def downgrade() -> None:
    op.alter_column('users', 'phone',
                    existing_type=sa.String(length=100),
                    type_=sa.String(length=20),
                    existing_nullable=True)
