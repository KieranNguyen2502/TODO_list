from supabase import create_client, Client

from app.config import settings

# One client, reused across requests. Created with the SECRET key —
# this process is the only place that key should ever live.
supabase: Client = create_client(settings.supabase_url, settings.supabase_secret_key)
