from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class SessionOut(BaseModel):
    token: str  # plaintext — only ever returned in this one response


class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)


class TodoUpdate(BaseModel):
    # Every field optional — PATCH semantics, only sent fields get changed.
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    completed: Optional[bool] = None


class TodoOut(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    completed: bool
    created_at: datetime
    updated_at: datetime
