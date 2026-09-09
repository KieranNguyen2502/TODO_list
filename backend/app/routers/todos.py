from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_owner
from app.database import supabase
from app.models import TodoCreate, TodoOut, TodoUpdate

router = APIRouter()


@router.get("/todos", response_model=List[TodoOut])
async def list_todos(owner_id: str = Depends(get_current_owner)):
    result = (
        supabase.table("todos")
        .select("*")
        .eq("owner_id", owner_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return result.data


@router.post("/todos", response_model=TodoOut, status_code=201)
async def create_todo(payload: TodoCreate, owner_id: str = Depends(get_current_owner)):
    result = (
        supabase.table("todos")
        .insert(
            {
                "owner_id": owner_id,
                "title": payload.title,
                "description": payload.description,
            }
        )
        .execute()
    )
    return result.data[0]


@router.patch("/todos/{todo_id}", response_model=TodoOut)
async def update_todo(
    todo_id: UUID, payload: TodoUpdate, owner_id: str = Depends(get_current_owner)
):
    updates = payload.model_dump(exclude_unset=True)
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    # .eq("owner_id", owner_id) here is the actual enforcement point:
    # a request can only ever touch rows matching its own resolved owner,
    # regardless of what todo_id it asks for.
    result = (
        supabase.table("todos")
        .update(updates)
        .eq("id", str(todo_id))
        .eq("owner_id", owner_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Todo not found")
    return result.data[0]


@router.patch("/todos/{todo_id}/complete", response_model=TodoOut)
async def complete_todo(todo_id: UUID, owner_id: str = Depends(get_current_owner)):
    result = (
        supabase.table("todos")
        .update({"completed": True})
        .eq("id", str(todo_id))
        .eq("owner_id", owner_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Todo not found")
    return result.data[0]


@router.delete("/todos/{todo_id}", status_code=204)
async def delete_todo(todo_id: UUID, owner_id: str = Depends(get_current_owner)):
    result = (
        supabase.table("todos")
        .delete()
        .eq("id", str(todo_id))
        .eq("owner_id", owner_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Todo not found")
