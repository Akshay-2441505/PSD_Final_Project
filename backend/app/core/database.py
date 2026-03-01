from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import settings

engine = create_engine(settings.DATABASE_URL)

@event.listens_for(engine, "connect")
def _set_public_search_path(dbapi_conn, connection_record):
    """
    Explicitly set search_path = public on every new connection.
    This guards against any stale search_path cached by the Supabase
    connection pooler (PgBouncer), e.g. after running pytest with test_schema.
    """
    cursor = dbapi_conn.cursor()
    cursor.execute("SET search_path TO public")
    cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
