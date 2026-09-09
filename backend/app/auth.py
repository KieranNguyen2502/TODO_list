from datetime import datetime, timezone

from fastapi import Header, HTTPException

from app.database import supabase
from app.security import hash_token


async def get_current_owner(authorization: str = Header(None)) -> str:
    """
    Every owner-scoped endpoint depends on this. It NEVER trusts an
    owner_id supplied by the client — the only input is the bearer
    token, and the only output is the owner_id resolved server-side
    from that token's hash.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or malformed Authorization header. Expected: Bearer <token>",
        )

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail="Missing token")

    token_hash = hash_token(token)

    result = (
        supabase.table("anonymous_sessions")
        .select("owner_id, revoked_at")
        .eq("token_hash", token_hash)
        .limit(1)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=401, detail="Invalid session token")

    session = result.data[0]
    if session.get("revoked_at"):
        raise HTTPException(status_code=401, detail="Session has been revoked")

    # Best-effort activity tracking — a failure here should never block
    # the actual request, so it's swallowed rather than raised.
    try:
        supabase.table("anonymous_sessions").update(
            {"last_used_at": datetime.now(timezone.utc).isoformat()}
        ).eq("owner_id", session["owner_id"]).execute()
    except Exception:
        pass

    return session["owner_id"]
