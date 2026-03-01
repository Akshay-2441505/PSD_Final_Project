from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

# connect_args options sets the search_path as a PostgreSQL startup parameter.
# This is the ONLY reliable way to override search_path when Supabase uses
# PgBouncer (transaction pooling) — because PgBouncer reuses physical connections
# and SQLAlchemy's 'connect' event only fires for brand-new TCP connections.
# Startup parameters are always re-applied by PgBouncer on every checkout.
engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"options": "-c search_path=public"},
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
