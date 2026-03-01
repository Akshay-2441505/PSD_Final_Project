"""
test_auth.py — Integration tests for /auth/* endpoints.
Tests: register, login, /auth/me, duplicate email, validation errors.
"""
import pytest
from tests.conftest import BORROWER_PAYLOAD, register_and_login_borrower


class TestBorrowerRegistration:

    def test_register_success(self, client):
        r = client.post("/auth/register", json=BORROWER_PAYLOAD)
        assert r.status_code == 200
        body = r.json()
        assert body["email"] == BORROWER_PAYLOAD["email"]
        assert "business_id" in body

    def test_register_duplicate_email_returns_409(self, client):
        client.post("/auth/register", json=BORROWER_PAYLOAD)
        r = client.post("/auth/register", json=BORROWER_PAYLOAD)
        assert r.status_code == 409

    def test_register_missing_required_field_returns_422(self, client):
        payload = {**BORROWER_PAYLOAD}
        del payload["email"]
        r = client.post("/auth/register", json=payload)
        assert r.status_code == 422

    def test_register_invalid_email_returns_422(self, client):
        payload = {**BORROWER_PAYLOAD, "email": "not-an-email"}
        r = client.post("/auth/register", json=payload)
        assert r.status_code == 422

    def test_register_short_password_returns_422(self, client):
        payload = {**BORROWER_PAYLOAD, "password": "abc"}
        r = client.post("/auth/register", json=payload)
        assert r.status_code == 422

    def test_register_stores_annual_turnover(self, client):
        r = client.post("/auth/register", json=BORROWER_PAYLOAD)
        assert r.json()["annual_turnover"] == BORROWER_PAYLOAD["annual_turnover"]


class TestBorrowerLogin:

    def test_login_success_returns_token(self, client):
        client.post("/auth/register", json=BORROWER_PAYLOAD)
        r = client.post("/auth/login", json={
            "email":    BORROWER_PAYLOAD["email"],
            "password": BORROWER_PAYLOAD["password"],
        })
        assert r.status_code == 200
        body = r.json()
        assert "access_token" in body
        assert body["token_type"] == "bearer"
        assert body["role"] == "borrower"

    def test_login_wrong_password_returns_401(self, client):
        client.post("/auth/register", json=BORROWER_PAYLOAD)
        r = client.post("/auth/login", json={
            "email":    BORROWER_PAYLOAD["email"],
            "password": "WrongPassword",
        })
        assert r.status_code == 401

    def test_login_unknown_email_returns_401(self, client):
        r = client.post("/auth/login", json={
            "email":    "nobody@example.com",
            "password": "Password@123",
        })
        assert r.status_code == 401


class TestGetMyProfile:

    def test_me_returns_profile(self, client):
        token = register_and_login_borrower(client)
        r = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 200
        assert r.json()["email"] == BORROWER_PAYLOAD["email"]

    def test_me_without_token_returns_403(self, client):
        r = client.get("/auth/me")
        assert r.status_code in (401, 403)

    def test_me_with_invalid_token_returns_401(self, client):
        r = client.get("/auth/me", headers={"Authorization": "Bearer invalid.token.here"})
        assert r.status_code == 401
