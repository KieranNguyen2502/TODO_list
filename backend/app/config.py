from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Typed wrapper around .env. Field names map to env var names
    case-insensitively (supabase_url -> SUPABASE_URL).
    """

    supabase_url: str
    supabase_secret_key: str  # sb_secret_... (or legacy service_role key)
    app_env: str = "local"
    cors_origins: str = "*"
    token_hash_secret: str

    class Config:
        env_file = ".env"


settings = Settings()
