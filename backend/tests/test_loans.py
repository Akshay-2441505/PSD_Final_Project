"""
test_loans.py — Integration tests for /loans/* borrower endpoints.
Tests: apply, multi-loan guard, get my loans, get specific loan.
"""
import pytest
from tests.conftest import BORROWER_PAYLOAD, register_and_login_borrower


LOAN_PAYLOAD = {
    "requested_amount": 500_000,
    "tenure_months":    24,
    "purpose":          "WORKING_CAPITAL",
    "declared_turnover": 2_000_000,
    "declared_profit":   400_000,
}


class TestLoanApplication:

    def test_apply_success_returns_201(self, client):
        token = register_and_login_borrower(client)
        r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 201

    def test_apply_returns_risk_score(self, client):
        token = register_and_login_borrower(client)
        r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        body = r.json()
        assert "risk_score" in body
        assert isinstance(body["risk_score"], int)
        assert 0 <= body["risk_score"] <= 100

    def test_apply_returns_score_breakdown(self, client):
        token = register_and_login_borrower(client)
        r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        body = r.json()
        assert "score_breakdown" in body
        assert isinstance(body["score_breakdown"], list)
        assert len(body["score_breakdown"]) == 5  # 5 rules in engine

    def test_apply_sets_status_to_pending(self, client):
        token = register_and_login_borrower(client)
        r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.json()["status"] == "PENDING"

    def test_apply_without_token_returns_403(self, client):
        r = client.post("/loans/apply", json=LOAN_PAYLOAD)
        assert r.status_code in (401, 403)

    def test_apply_with_missing_amount_returns_422(self, client):
        token = register_and_login_borrower(client)
        payload = {**LOAN_PAYLOAD}
        del payload["requested_amount"]
        r = client.post(
            "/loans/apply",
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 422

    def test_apply_high_risk_loan_still_creates(self, client):
        """A risky application must still get created (admin decides, not the engine)."""
        token = register_and_login_borrower(client)
        risky_payload = {
            "requested_amount": 1_900_000,  # huge amount
            "tenure_months":    60,          # long tenure
            "purpose":          "EXPANSION",
            "declared_turnover": 500_000,    # tiny turnover
            "declared_profit":   -10_000,    # loss-making
        }
        r = client.post(
            "/loans/apply",
            json=risky_payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 201
        assert r.json()["risk_score"] < 30


class TestMultiLoanGuard:
    """POST /loans/apply must return 409 if borrower has an active APPROVED loan."""

    def _approve_loan(self, client, admin_token, app_id):
        client.patch(
            f"/admin/applications/{app_id}/decision",
            json={"decision": "APPROVED", "remarks": "Auto-approved in test"},
            headers={"Authorization": f"Bearer {admin_token}"},
        )

    def test_second_application_blocked_when_approved_loan_exists(self, client):
        token = register_and_login_borrower(client)

        # First application
        r1 = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r1.status_code == 201
        app_id = r1.json()["app_id"]

        # Manually approve via admin (need admin token)
        from app.models.models import LoanApplication, LoanStatus
        from sqlalchemy.orm import Session
        # Direct DB manipulation via the test DB session is done through the API
        # We use the admin endpoint to approve
        admin_r = client.post("/auth/admin/login", json={"email": "admin@lendingapp.com", "password": "Admin@123"})
        if admin_r.status_code == 200:
            admin_token = admin_r.json()["access_token"]
            self._approve_loan(client, admin_token, app_id)

            # Second application should be blocked
            r2 = client.post(
                "/loans/apply",
                json=LOAN_PAYLOAD,
                headers={"Authorization": f"Bearer {token}"},
            )
            assert r2.status_code == 409
            assert r2.json()["detail"]["code"] == "ACTIVE_LOAN_EXISTS"
        else:
            pytest.skip("Admin account not seeded — skipping multi-loan guard integration test")


class TestGetMyLoans:

    def test_get_my_loans_returns_list(self, client):
        token = register_and_login_borrower(client)
        r = client.get("/loans/my", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_get_my_loans_after_apply_returns_one(self, client):
        token = register_and_login_borrower(client)
        client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        r = client.get("/loans/my", headers={"Authorization": f"Bearer {token}"})
        assert len(r.json()) == 1

    def test_get_specific_loan(self, client):
        token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token}"},
        )
        app_id = apply_r.json()["app_id"]
        r = client.get(f"/loans/{app_id}", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 200
        assert r.json()["app_id"] == app_id

    def test_get_other_borrowers_loan_returns_403_or_404(self, client):
        """Borrower A should not be able to read Borrower B's loan."""
        # Register borrower A and apply
        token_a = register_and_login_borrower(client, BORROWER_PAYLOAD)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {token_a}"},
        )
        app_id = apply_r.json()["app_id"]

        # Register borrower B
        payload_b = {**BORROWER_PAYLOAD, "email": "b@example.com"}
        token_b = register_and_login_borrower(client, payload_b)

        r = client.get(f"/loans/{app_id}", headers={"Authorization": f"Bearer {token_b}"})
        assert r.status_code in (403, 404)
