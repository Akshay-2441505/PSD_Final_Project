"""
admin.py — Admin-facing endpoints: view, review, and decide on loan applications.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.models.models import (
    LoanApplication, BorrowerProfile, ApplicationStatusLog, AdminUser, LoanStatus
)
from app.schemas.schemas import (
    AdminApplicationListItem, AdminApplicationDetail,
    AdminDecisionRequest, MessageResponse, ChartDataResponse
)

router = APIRouter()


# ── GET /admin/portfolio/stats ─────────────────────────────────────────────
@router.get("/portfolio/stats")
def portfolio_stats(
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """Portfolio-level summary for the admin dashboard."""
    all_loans = db.query(LoanApplication).all()
    total = len(all_loans)
    approved = [l for l in all_loans if l.status == LoanStatus.APPROVED]
    rejected = [l for l in all_loans if l.status == LoanStatus.REJECTED]
    pending  = [l for l in all_loans if l.status in {LoanStatus.PENDING, LoanStatus.UNDER_REVIEW}]

    total_disbursed = sum(float(l.requested_amount) for l in approved)
    approval_rate   = round(len(approved) / total * 100, 1) if total else 0
    avg_risk_score  = (
        round(sum(l.risk_score for l in all_loans if l.risk_score) / total, 1)
        if total else 0
    )

    return {
        "total_applications":  total,
        "approved_count":      len(approved),
        "rejected_count":      len(rejected),
        "pending_count":       len(pending),
        "total_disbursed":     total_disbursed,
        "approval_rate":       approval_rate,
        "avg_risk_score":      avg_risk_score,
    }


# ── GET /admin/applications ───────────────────────────────────────────────
@router.get("/applications", response_model=List[AdminApplicationListItem])
def list_applications(
    status: str = None,
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """List all loan applications. Optionally filter by status."""
    query = db.query(LoanApplication, BorrowerProfile).join(
        BorrowerProfile, LoanApplication.business_id == BorrowerProfile.business_id
    )
    if status:
        query = query.filter(LoanApplication.status == status)

    results = query.order_by(LoanApplication.created_at.desc()).all()

    return [
        AdminApplicationListItem(
            app_id=loan.app_id,
            business_id=loan.business_id,
            legal_name=borrower.legal_name,
            owner_name=borrower.owner_name,
            requested_amount=float(loan.requested_amount),
            tenure_months=loan.tenure_months,
            purpose=loan.purpose,
            status=loan.status,
            risk_score=loan.risk_score,
            risk_flags=loan.risk_flags or [],
            created_at=loan.created_at,
        )
        for loan, borrower in results
    ]


# ── GET /admin/applications/{app_id} ─────────────────────────────────────
@router.get("/applications/{app_id}", response_model=AdminApplicationDetail)
def get_application_detail(
    app_id: UUID,
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """Full detail of one loan application including borrower profile."""
    # Two separate queries instead of a JOIN — more reliable with PgBouncer
    loan = db.query(LoanApplication).filter(LoanApplication.app_id == app_id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Application not found")

    borrower = db.query(BorrowerProfile).filter(
        BorrowerProfile.business_id == loan.business_id
    ).first()
    if not borrower:
        raise HTTPException(status_code=404, detail="Borrower profile not found")

    return AdminApplicationDetail(
        app_id=loan.app_id,
        business_id=loan.business_id,
        requested_amount=float(loan.requested_amount),
        tenure_months=loan.tenure_months,
        purpose=loan.purpose,
        declared_turnover=float(loan.declared_turnover) if loan.declared_turnover else None,
        declared_profit=float(loan.declared_profit) if loan.declared_profit else None,
        status=loan.status,
        risk_score=loan.risk_score,
        risk_flags=loan.risk_flags or [],
        score_breakdown=loan.score_breakdown or [],
        repayment_schedule=loan.repayment_schedule,
        admin_remarks=loan.admin_remarks,
        bank_statement_data=loan.bank_statement_data,
        created_at=loan.created_at,
        updated_at=loan.updated_at,
        legal_name=borrower.legal_name,
        owner_name=borrower.owner_name,
        email=borrower.email,
        phone=borrower.phone,
        gstin=borrower.gstin,
        annual_turnover=float(borrower.annual_turnover) if borrower.annual_turnover else None,
        annual_profit=float(borrower.annual_profit) if borrower.annual_profit else None,
    )


# ── PATCH /admin/applications/{app_id}/decision ───────────────────────────
@router.patch("/applications/{app_id}/decision", response_model=MessageResponse)
def make_decision(
    app_id: UUID,
    payload: AdminDecisionRequest,
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """Approve, Reject, or Request More Info on a loan application."""
    loan = db.query(LoanApplication).filter(LoanApplication.app_id == app_id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Application not found")

    from app.services.amortization import generate_schedule
    from datetime import datetime

    old_status = loan.status
    loan.status = payload.decision
    loan.admin_remarks = payload.remarks

    # On approval — generate & store full amortization schedule
    if str(payload.decision) in ("APPROVED", LoanStatus.APPROVED.value):
        schedule = generate_schedule(
            principal=float(loan.requested_amount),
            tenure_months=loan.tenure_months,
            start_date=datetime.utcnow(),
        )
        loan.repayment_schedule = schedule

    log = ApplicationStatusLog(
        app_id=app_id,
        old_status=old_status,
        new_status=payload.decision,
        changed_by=admin.email,
        remarks=payload.remarks,
    )
    db.add(log)
    db.commit()

    return MessageResponse(message=f"Application {payload.decision.value} successfully")


# ── Helpers ────────────────────────────────────────────────────────────────
import random as _random
import hashlib as _hashlib
import calendar as _calendar

def _business_rng(business_id: str, salt: str = "") -> _random.Random:
    """Return a Random() seeded deterministically from business_id + optional salt.
    Using salt=purpose for expense charts, salt=turnover_bucket for revenue charts
    ensures visually distinct charts across different loan types/scales."""
    seed_str = f"{business_id}::{salt}"
    seed_int = int(_hashlib.md5(seed_str.encode()).hexdigest(), 16) % (2 ** 31)
    return _random.Random(seed_int)

def _extract_purpose(loan) -> str:
    """Safely extract purpose string from a loan regardless of enum/string type."""
    if loan is None or loan.purpose is None:
        return ""
    p = loan.purpose
    return p.value if hasattr(p, 'value') else str(p)

# Purpose → expense weight profile (which categories dominate)
_PURPOSE_WEIGHTS = {
    "EQUIPMENT_PURCHASE": {"Raw Materials": 40, "Salaries": 20, "Rent": 10, "Utilities": 10, "Logistics": 10, "Equipment": 10},
    "WORKING_CAPITAL":    {"Raw Materials": 25, "Salaries": 30, "Rent": 20, "Utilities": 10, "Logistics": 10, "Marketing": 5},
    "EXPANSION":          {"Raw Materials": 20, "Salaries": 25, "Rent": 15, "Logistics": 15, "Marketing": 20, "Utilities": 5},
    "INVENTORY":          {"Raw Materials": 45, "Logistics": 20, "Salaries": 15, "Rent": 10, "Utilities": 5, "Other": 5},
    "TECHNOLOGY":         {"Salaries": 40, "Software": 20, "Rent": 15, "Marketing": 15, "Utilities": 10},
    "MARKETING":          {"Marketing": 40, "Salaries": 25, "Rent": 15, "Logistics": 10, "Utilities": 10},
}
_DEFAULT_WEIGHTS = {"Raw Materials": 30, "Salaries": 25, "Rent": 20, "Utilities": 10, "Logistics": 10, "Marketing": 5}


# ── GET /admin/charts/expenses ─────────────────────────────────────────────
@router.get("/charts/expenses")
def get_expense_chart(
    app_id: str = None,
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """
    Expense breakdown — Priority:
    1. Real AA bank_statement_data (most accurate)
    2. Deterministic seeded mock, scaled by turnover + skewed by purpose
    """
    from uuid import UUID as _UUID
    from collections import defaultdict

    loan = None
    if app_id:
        try:
            loan = db.query(LoanApplication).filter(
                LoanApplication.app_id == _UUID(app_id)
            ).first()
        except Exception:
            pass

    # ── Priority 1: Real AA data ──────────────────────────────────────────
    if loan and loan.bank_statement_data:
        txns = loan.bank_statement_data.get("transactions", [])
        debits = [t for t in txns if t.get("type") == "debit"]
        buckets: dict = defaultdict(float)
        keyword_map = {
            "Raw Material": "Raw Materials", "Staff Salary": "Salaries",
            "Rent": "Rent", "Utility": "Utilities", "Logistics": "Logistics",
            "Equipment": "Equipment", "Marketing": "Marketing",
        }
        for t in debits:
            desc = t.get("description", "")
            matched = False
            for kw, bucket in keyword_map.items():
                if kw.lower() in desc.lower():
                    buckets[bucket] += t.get("amount", 0)
                    matched = True
                    break
            if not matched:
                buckets["Other"] += t.get("amount", 0)
        non_zero = {k: v for k, v in buckets.items() if v > 0}
        # Guard: stale data with only 1-2 categories → fall through to seeded mock
        if len(non_zero) >= 3:
            return {"categories": list(non_zero.keys()), "values": list(non_zero.values())}

    # ── Priority 2: Deterministic seeded mock ─────────────────────────────
    # Seed includes PURPOSE so EQUIPMENT_PURCHASE vs WORKING_CAPITAL from
    # the SAME business produces completely different pie charts.
    business_id = str(loan.business_id) if loan else (app_id or "default")
    purpose     = _extract_purpose(loan)          # safe enum / string helper
    turnover    = float(loan.declared_turnover or 1200000) if loan else 1200000

    rng     = _business_rng(business_id, salt=purpose)   # ← purpose in seed
    weights = _PURPOSE_WEIGHTS.get(purpose, _DEFAULT_WEIGHTS)
    total_w = sum(weights.values())

    # Scale total expenses to ~55-70% of annual turnover, split by weights
    expense_ratio = 0.55 + rng.random() * 0.15
    total_expense = turnover * expense_ratio

    categories, values = [], []
    for cat, w in weights.items():
        base  = (w / total_w) * total_expense
        noise = 1.0 + (rng.random() * 0.40 - 0.20)  # wider ±20% noise → more contrast
        categories.append(cat)
        values.append(max(1, round(base * noise)))

    return {"categories": categories, "values": values}


# ── GET /admin/charts/revenue ──────────────────────────────────────────────
@router.get("/charts/revenue")
def get_revenue_chart(
    app_id: str = None,
    db: Session = Depends(get_db),
    admin: AdminUser = Depends(get_current_admin),
):
    """
    Monthly revenue trend — Priority:
    1. Real AA bank_statement_data credit transactions
    2. Deterministic seeded mock: 6 months, scaled by declared_turnover
    """
    from uuid import UUID as _UUID
    from collections import defaultdict

    loan = None
    if app_id:
        try:
            loan = db.query(LoanApplication).filter(
                LoanApplication.app_id == _UUID(app_id)
            ).first()
        except Exception:
            pass

    # ── Priority 1: Real AA data (only if spans ≥3 distinct months) ────────
    if loan and loan.bank_statement_data:
        txns    = loan.bank_statement_data.get("transactions", [])
        credits = [t for t in txns if t.get("type") == "credit"]
        monthly: dict = defaultdict(float)
        for t in credits:
            d = t.get("date", "")
            if len(d) >= 7:
                monthly[d[:7]] += t.get("amount", 0)
        # Guard: stale data seeded in a single month → skip to fresh mock
        if len(monthly) >= 3:
            sorted_months = sorted(monthly.keys())
            labels = [_calendar.month_abbr[int(m.split("-")[1])] for m in sorted_months]
            return {"months": labels, "revenue": [monthly[m] for m in sorted_months]}

    # ── Priority 2: Deterministic seeded mock ─────────────────────────────
    # Seed includes TURNOVER BUCKET so ₹5L and ₹50L businesses have distinctly
    # different trend shapes (not just different Y-scales).
    business_id     = str(loan.business_id) if loan else (app_id or "default")
    turnover        = float(loan.declared_turnover or 1200000) if loan else 1200000
    turnover_bucket = str(int(turnover / 500000))   # bucket in ₹5L steps
    rng             = _business_rng(business_id, salt=turnover_bucket)  # ← turnover in seed

    monthly_avg  = turnover / 12
    growth       = 1.0 + rng.random() * 0.40   # wider range: 0–40% annual growth
    volatility   = 0.15 + rng.random() * 0.35  # each biz has its own ±volatility
    month_labels = ["Sep", "Oct", "Nov", "Dec", "Jan", "Feb"]
    revenue      = []
    for i in range(6):
        trend_factor = 1.0 + (growth - 1.0) * (i / 5)
        noise_factor = 1.0 + (rng.random() * volatility * 2 - volatility)
        revenue.append(max(1, round(monthly_avg * trend_factor * noise_factor)))

    return {"months": month_labels, "revenue": revenue}
