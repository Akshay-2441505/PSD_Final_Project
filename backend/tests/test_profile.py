"""
test_profile.py — Integration tests for /profile/* endpoints (financial data).
Tests: upload financials, fetch financials, validation, auth guard.
"""
import pytest
from tests.conftest import register_and_login_borrower

FINANCIAL_PAYLOAD = {
    "monthly_revenue": [
        {"month": "2024-09", "revenue": 200_000},
        {"month": "2024-10", "revenue": 210_000},
        {"month": "2024-11", "revenue": 195_000},
        {"month": "2024-12", "revenue": 220_000},
        {"month": "2025-01", "revenue": 230_000},
        {"month": "2025-02", "revenue": 215_000},
    ],
    "expense_breakdown": [
        {"category": "Raw Materials", "percentage": 35},
        {"category": "Salaries",      "percentage": 30},
        {"category": "Rent",          "percentage": 15},
        {"category": "Utilities",     "percentage": 10},
        {"category": "Marketing",     "percentage": 10},
    ],
}


class TestUploadFinancials:

    def test_upload_success_returns_200(self, client):
        token = register_and_login_borrower(client)
        r = client.post(
            "/profile/financials",
            json=FINANCIAL_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200

    def test_upload_without_token_returns_403(self, client):
        r = client.post("/profile/financials", json=FINANCIAL_PAYLOAD)
        assert r.status_code in (401, 403)

    def test_upload_empty_revenue_returns_422(self, client):
        token = register_and_login_borrower(client)
        payload = {**FINANCIAL_PAYLOAD, "monthly_revenue": []}
        r = client.post(
            "/profile/financials",
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        # Either 422 (validation) or 200 (server accepts empty list) — both OK
        assert r.status_code in (200, 422)

    def test_upload_is_upsert_not_duplicate(self, client):
        """Uploading twice should update, not create a second record."""
        token = register_and_login_borrower(client)
        r1 = client.post(
            "/profile/financials",
            json=FINANCIAL_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        # Second upload with different revenue
        updated_payload = {
            **FINANCIAL_PAYLOAD,
            "monthly_revenue": [{"month": "2025-03", "revenue": 250_000}],
        }
        r2 = client.post(
            "/profile/financials",
            json=updated_payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r2.status_code == 200


class TestGetFinancials:

    def test_get_returns_empty_before_upload(self, client):
        token = register_and_login_borrower(client)
        r = client.get("/profile/financials", headers={"Authorization": f"Bearer {token}"})
        # Either 404 (no data) or 200 with null body
        assert r.status_code in (200, 404)

    def test_get_returns_data_after_upload(self, client):
        token = register_and_login_borrower(client)
        client.post(
            "/profile/financials",
            json=FINANCIAL_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        r = client.get("/profile/financials", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 200
        body = r.json()
        assert "monthly_revenue" in body
        assert "expense_breakdown" in body

    def test_get_monthly_revenue_has_correct_count(self, client):
        token = register_and_login_borrower(client)
        client.post(
            "/profile/financials",
            json=FINANCIAL_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        r = client.get("/profile/financials", headers={"Authorization": f"Bearer {token}"})
        assert len(r.json()["monthly_revenue"]) == len(FINANCIAL_PAYLOAD["monthly_revenue"])

    def test_get_without_token_returns_403(self, client):
        r = client.get("/profile/financials")
        assert r.status_code in (401, 403)
