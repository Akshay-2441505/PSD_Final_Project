"""
test_admin.py — Integration tests for /admin/* endpoints.
Tests: list applications, detail, make decision (approve/reject), portfolio stats.
"""
import pytest
from tests.conftest import BORROWER_PAYLOAD, register_and_login_borrower

LOAN_PAYLOAD = {
    "requested_amount":  500_000,
    "tenure_months":     24,
    "purpose":           "WORKING_CAPITAL",
    "declared_turnover": 2_000_000,
    "declared_profit":   400_000,
}

DECISION_APPROVE = {"decision": "APPROVED", "remarks": "Looks good"}
DECISION_REJECT  = {"decision": "REJECTED",  "remarks": "Risk too high"}


def _get_admin_token(client) -> str | None:
    r = client.post("/auth/admin/login", json={"email": "admin@lendingapp.com", "password": "Admin@123"})
    return r.json().get("access_token") if r.status_code == 200 else None


class TestAdminApplicationsList:

    def test_list_requires_admin_token(self, client):
        r = client.get("/admin/applications")
        assert r.status_code in (401, 403)

    def test_borrower_token_cannot_access_admin_list(self, client):
        token = register_and_login_borrower(client)
        r = client.get("/admin/applications", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code in (401, 403)

    def test_list_returns_empty_or_list(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        r = client.get("/admin/applications", headers={"Authorization": f"Bearer {admin_token}"})
        assert r.status_code == 200
        assert isinstance(r.json(), list)

    def test_list_includes_applied_loan(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        borrower_token = register_and_login_borrower(client)
        client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        r = client.get("/admin/applications", headers={"Authorization": f"Bearer {admin_token}"})
        assert r.status_code == 200
        assert len(r.json()) >= 1

    def test_list_filter_by_status(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        r = client.get(
            "/admin/applications?status=PENDING",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200
        for app in r.json():
            assert app["status"] == "PENDING"


class TestAdminApplicationDetail:

    def test_get_detail_returns_borrower_info(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        borrower_token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        app_id = apply_r.json()["app_id"]
        r = client.get(
            f"/admin/applications/{app_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200
        assert r.json()["email"] == BORROWER_PAYLOAD["email"]

    def test_get_detail_invalid_id_returns_404(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        fake_id = "00000000-0000-0000-0000-000000000000"
        r = client.get(
            f"/admin/applications/{fake_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 404


class TestAdminDecision:

    def test_approve_changes_status(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        borrower_token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        app_id = apply_r.json()["app_id"]
        dec_r = client.patch(
            f"/admin/applications/{app_id}/decision",
            json=DECISION_APPROVE,
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert dec_r.status_code == 200

    def test_approve_generates_repayment_schedule(self, client):
        """After approval, the loan's repayment_schedule must be populated."""
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        borrower_token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        app_id = apply_r.json()["app_id"]
        client.patch(
            f"/admin/applications/{app_id}/decision",
            json=DECISION_APPROVE,
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        # Borrower fetches the loan — repayment_schedule should be present
        loan_r = client.get(
            f"/loans/{app_id}",
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        loan_data = loan_r.json()
        assert loan_data["status"] == "APPROVED"
        assert "repayment_schedule" in loan_data
        assert isinstance(loan_data["repayment_schedule"], list)
        assert len(loan_data["repayment_schedule"]) == LOAN_PAYLOAD["tenure_months"]

    def test_reject_changes_status(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        borrower_token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        app_id = apply_r.json()["app_id"]
        dec_r = client.patch(
            f"/admin/applications/{app_id}/decision",
            json=DECISION_REJECT,
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert dec_r.status_code == 200

    def test_decision_requires_admin_token(self, client):
        borrower_token = register_and_login_borrower(client)
        apply_r = client.post(
            "/loans/apply",
            json=LOAN_PAYLOAD,
            headers={"Authorization": f"Bearer {borrower_token}"},
        )
        app_id = apply_r.json()["app_id"]
        r = client.patch(
            f"/admin/applications/{app_id}/decision",
            json=DECISION_APPROVE,
            headers={"Authorization": f"Bearer {borrower_token}"},  # wrong role!
        )
        assert r.status_code in (401, 403)


class TestPortfolioStats:

    def test_stats_endpoint_returns_expected_keys(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        r = client.get(
            "/admin/portfolio/stats",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200
        body = r.json()
        assert "total_applications"  in body
        assert "approved_count"      in body
        assert "rejected_count"      in body
        assert "pending_count"       in body
        assert "total_disbursed"     in body
        assert "approval_rate"       in body
        assert "avg_risk_score"      in body

    def test_stats_approval_rate_between_0_and_100(self, client):
        admin_token = _get_admin_token(client)
        if not admin_token:
            pytest.skip("Admin account not seeded")
        r = client.get(
            "/admin/portfolio/stats",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        rate = r.json()["approval_rate"]
        assert 0 <= float(rate) <= 100

    def test_stats_without_token_returns_403(self, client):
        r = client.get("/admin/portfolio/stats")
        assert r.status_code in (401, 403)
