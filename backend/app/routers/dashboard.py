"""
dashboard.py — Borrower dashboard insights endpoint.
Returns real financial data if available, else falls back to a projection from annual_turnover.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
import calendar
from datetime import datetime, timedelta

from app.core.database import get_db
from app.core.dependencies import get_current_borrower
from app.models.models import LoanApplication, LoanStatus, BorrowerProfile, BorrowerFinancial
from app.schemas.schemas import DashboardInsightsResponse

router = APIRouter()


def _generate_projected_revenue(annual_turnover: float) -> List[dict]:
    """Generate 6-month projected monthly revenue from annual turnover.
    Uses slight monthly variation to make it realistic.
    """
    base = annual_turnover / 12
    multipliers = [0.85, 0.90, 0.95, 1.00, 1.05, 1.10]
    months = []
    now = datetime.now()
    for i in range(5, -1, -1):
        dt = now - timedelta(days=30 * i)
        month_name = dt.strftime("%b")
        months.append({
            "month": month_name,
            "revenue": round(base * multipliers[5 - i]),
        })
    return months


def _default_expense_breakdown() -> List[dict]:
    return [
        {"category": "Raw Materials", "percentage": 35},
        {"category": "Salaries",      "percentage": 25},
        {"category": "Rent",          "percentage": 15},
        {"category": "Utilities",     "percentage": 8},
        {"category": "Logistics",     "percentage": 10},
        {"category": "Marketing",     "percentage": 7},
    ]


@router.get("/insights", response_model=DashboardInsightsResponse)
def get_dashboard_insights(
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Aggregated financial insights for the borrower dashboard."""
    loans = db.query(LoanApplication).filter(
        LoanApplication.business_id == borrower.business_id
    ).all()

    total_applications = len(loans)
    approved_amount = sum(
        float(l.requested_amount) for l in loans if l.status == LoanStatus.APPROVED
    )
    pending_count = sum(
        1 for l in loans if l.status in {LoanStatus.PENDING, LoanStatus.UNDER_REVIEW}
    )

    # Health score: based on average risk scores
    avg_risk = (
        sum(l.risk_score for l in loans if l.risk_score is not None) / total_applications
        if total_applications else 75
    )
    health_score = int(avg_risk)

    # ── Real financial data (from borrower_financials table) ────────────────
    financials = db.query(BorrowerFinancial).filter(
        BorrowerFinancial.business_id == borrower.business_id
    ).first()

    if financials and financials.monthly_revenue:
        monthly_revenue = financials.monthly_revenue
    elif borrower.annual_turnover:
        # Fall back to projected data from annual_turnover ─────────────────
        monthly_revenue = _generate_projected_revenue(float(borrower.annual_turnover))
    else:
        # Last resort: static sample data
        monthly_revenue = [
            {"month": "Sep", "revenue": 820000},
            {"month": "Oct", "revenue": 950000},
            {"month": "Nov", "revenue": 870000},
            {"month": "Dec", "revenue": 1100000},
            {"month": "Jan", "revenue": 1050000},
            {"month": "Feb", "revenue": 1230000},
        ]

    if financials and financials.expense_breakdown:
        expense_breakdown = financials.expense_breakdown
    else:
        expense_breakdown = _default_expense_breakdown()

    # Next EMI due: 30 days from latest approved loan approval
    approved_loan = next((l for l in loans if l.status == LoanStatus.APPROVED), None)
    next_emi_due = None
    if approved_loan and approved_loan.updated_at:
        next_emi = approved_loan.updated_at + timedelta(days=30)
        next_emi_due = next_emi.strftime("%Y-%m-%d")
    elif approved_loan:
        next_emi_due = "2025-03-05"  # fallback for old records

    return DashboardInsightsResponse(
        total_applications=total_applications,
        approved_amount=approved_amount,
        pending_count=pending_count,
        next_emi_due=next_emi_due,
        health_score=health_score,
        monthly_revenue=monthly_revenue,
        expense_breakdown=expense_breakdown,
    )
