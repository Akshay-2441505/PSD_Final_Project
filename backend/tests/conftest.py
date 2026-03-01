"""
conftest.py — Shared pytest fixtures for the MSME Lending API test suite.

Uses the REAL PostgreSQL database with a dedicated 'test_schema' schema so JSONB works.
The search_path is set PER CONNECTION on the test engine only — it never touches
the database-level default, so production tables remain untouched after tests finish.
"""
import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app

# ── Load DB URL ────────────────────────────────────────────────────────────────
_DB_URL = os.environ.get("TEST_DATABASE_URL") or os.environ.get("DATABASE_URL", "")
if not _DB_URL:
    try:
        from dotenv import load_dotenv
        load_dotenv()
        _DB_URL = os.environ.get("DATABASE_URL", "")
    except ImportError:
        pass

# ── Test engine with per-connection search_path (never leaks to prod) ─────────
_engine = create_engine(_DB_URL)

@event.listens_for(_engine, "connect")
def _set_test_search_path(dbapi_conn, connection_record):
    """
    Runs on every new connection from the TEST engine only.
    Sets search_path = test_schema so SQLAlchemy resolves tables there.
    This is NOT ALTER DATABASE — it only lasts for the connection lifetime.
    """
    cursor = dbapi_conn.cursor()
    cursor.execute("SET search_path TO test_schema, public")
    cursor.close()

_TestSession = sessionmaker(autocommit=False, autoflush=False, bind=_engine)


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Create test_schema + all tables once. Drop everything after the session."""
    with _engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS test_schema"))
        conn.commit()

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
