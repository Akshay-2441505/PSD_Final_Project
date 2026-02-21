"""
dashboard.py — Borrower dashboard insights endpoint.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_borrower
from app.models.models import LoanApplication, LoanStatus, BorrowerProfile
from app.schemas.schemas import DashboardInsightsResponse

router = APIRouter()


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

    # Health score: based on approval rate and risk scores
    avg_risk = (
        sum(l.risk_score for l in loans if l.risk_score is not None) / total_applications
        if total_applications else 75
    )
    health_score = int(avg_risk)

    # Simulated monthly revenue (last 6 months)
    monthly_revenue = [
        {"month": "Sep", "revenue": 820000},
        {"month": "Oct", "revenue": 950000},
        {"month": "Nov", "revenue": 870000},
        {"month": "Dec", "revenue": 1100000},
        {"month": "Jan", "revenue": 1050000},
        {"month": "Feb", "revenue": 1230000},
    ]

    # Simulated expense breakdown
    expense_breakdown = [
        {"category": "Raw Materials", "percentage": 35},
        {"category": "Salaries",      "percentage": 25},
        {"category": "Rent",          "percentage": 15},
        {"category": "Utilities",     "percentage": 8},
        {"category": "Logistics",     "percentage": 10},
        {"category": "Marketing",     "percentage": 7},
    ]

    # Next EMI (simulated)
    approved_loan = next((l for l in loans if l.status == LoanStatus.APPROVED), None)
    next_emi_due = "2025-03-05" if approved_loan else None

    return DashboardInsightsResponse(
        total_applications=total_applications,
        approved_amount=approved_amount,
        pending_count=pending_count,
        next_emi_due=next_emi_due,
        health_score=health_score,
        monthly_revenue=monthly_revenue,
        expense_breakdown=expense_breakdown,
    )
