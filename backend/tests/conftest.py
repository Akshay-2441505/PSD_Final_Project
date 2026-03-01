"""
conftest.py — Shared pytest fixtures for the MSME Lending API test suite.

Uses the REAL PostgreSQL database with a dedicated test schema so JSONB works.
All test tables are created, tests run, then tables are dropped — no data pollution.
"""
import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app

# ── PostgreSQL URL (same Supabase DB, test_ prefix for table isolation) ───────
# We set search_path to a test schema so real tables are untouched.
_DB_URL = os.environ.get(
    "TEST_DATABASE_URL",
    os.environ.get("DATABASE_URL", "")   # fallback to production URL
)

# If no DATABASE_URL at all, try loading from .env manually
if not _DB_URL:
    try:
        from dotenv import load_dotenv
        load_dotenv()
        _DB_URL = os.environ.get("DATABASE_URL", "")
    except ImportError:
        pass

_engine = create_engine(_DB_URL)
_TestSession = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """
    Create a fresh copy of all tables in the 'test_schema' PostgreSQL schema.
    Drop them after the entire test session.
    """
    with _engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS test_schema"))
        conn.commit()

    # Re-bind metadata to test_schema by setting search_path per connection
    @event.listens_for(_engine, "connect")
    def set_search_path(dbapi_conn, connection_record):
        dbapi_conn.autocommit = True
        cursor = dbapi_conn.cursor()
        cursor.execute("SET search_path TO test_schema, public")
        cursor.close()
        dbapi_conn.autocommit = False

    Base.metadata.create_all(bind=_engine)
    yield
    Base.metadata.drop_all(bind=_engine)
    with _engine.connect() as conn:
        conn.execute(text("DROP SCHEMA IF EXISTS test_schema CASCADE"))
        conn.commit()


@pytest.fixture
def db_session():
    """Per-test session wrapped in a savepoint that rolls back after the test."""
    connection = _engine.connect()
    transaction = connection.begin()
    session = _TestSession(bind=connection)

    nested = connection.begin_nested()

    @event.listens_for(session, "after_transaction_end")
    def restart_savepoint(session, trans):
        nonlocal nested
        if not nested.is_active:
            nested = connection.begin_nested()

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session):
    """TestClient overriding get_db with the test session."""
    def _override():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = _override
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c
    app.dependency_overrides.clear()


# ── Shared payloads ────────────────────────────────────────────────────────────

BORROWER_PAYLOAD = {
    "legal_name":      "Test Business Pvt Ltd",
    "owner_name":      "Test Owner",
    "email":           "testborrower@example.com",
    "phone":           "9876543210",
    "password":        "Password@123",
    "gstin":           "29ABCDE1234F1Z5",
    "business_type":   "Manufacturing",
    "annual_turnover": 2_000_000,
    "annual_profit":   400_000,
}

ADMIN_CREDENTIALS = {
    "email":    "admin@lendingapp.com",
    "password": "Admin@123",
}


def register_and_login_borrower(client, payload: dict = None) -> str:
    """Register a fresh borrower and return their JWT token."""
    data = payload or BORROWER_PAYLOAD
    client.post("/auth/register", json=data)
    r = client.post("/auth/login", json={"email": data["email"], "password": data["password"]})
    return r.json().get("access_token", "")


def login_admin(client) -> str | None:
    """Log in as the seeded admin and return the JWT token, or None if not seeded."""
    r = client.post("/auth/admin/login", json=ADMIN_CREDENTIALS)
    return r.json().get("access_token") if r.status_code == 200 else None
