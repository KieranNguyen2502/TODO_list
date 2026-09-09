from fastapi import APIRouter

from app.database import supabase
from app.models import SessionOut
from app.security import generate_token, hash_token

router = APIRouter()


@router.post("/anonymous-session", response_model=SessionOut, status_code=201)
async def create_anonymous_session():
    """
    Called once, on first launch, when the device has no stored token.
    Returns the plaintext token exactly once — the device is responsible
    for storing it in secure storage from here on.
    """
    token = generate_token()
    token_hash = hash_token(token)

    supabase.table("anonymous_sessions").insert({"token_hash": token_hash}).execute()

    return SessionOut(token=token)
