import hashlib
import hmac
import secrets

from app.config import settings


def generate_token() -> str:
    """
    Plaintext token handed to the device. Returned to the client exactly
    once, at session creation — never stored server-side in plaintext.
    """
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    """
    Deterministic HMAC-SHA256 hash of a token, keyed by TOKEN_HASH_SECRET.
    Storing this instead of the plaintext token means a leaked database
    row cannot be used to reconstruct a working session token, and a
    leaked device token cannot be reversed into the hash-secret.
    """
    return hmac.new(
        settings.token_hash_secret.encode("utf-8"),
        token.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
