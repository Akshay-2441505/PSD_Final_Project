from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

# ── Engine ─────────────────────────────────────────────────────────────────
# Supabase uses PgBouncer in transaction pooling mode.
# Key rules for PgBouncer compatibility:
#   1. NO startup parameters via connect_args (breaks PgBouncer checkout)
#   2. pool_pre_ping=True — tests the connection before use, discards stale ones
#   3. pool_recycle — prevents connections from going stale over long idle periods
#   4. pool_size + max_overflow limit concurrent connection count vs Supabase free tier

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,        # drop stale/dead connections automatically
    pool_recycle=300,          # recycle connections every 5 minutes
    pool_size=5,               # keep at most 5 idle connections
    max_overflow=10,           # allow up to 10 extra connections under load
    connect_args={
        "connect_timeout": 10, # fail fast instead of hanging forever
        "sslmode": "require",  # enforce SSL for Supabase
    },
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
