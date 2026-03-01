"""
loans.py — Borrower-facing loan endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.dependencies import get_current_borrower
from app.models.models import LoanApplication, ApplicationStatusLog, LoanStatus, BorrowerProfile
from app.schemas.schemas import (
    LoanApplyRequest, LoanApplicationResponse,
    AccountAggregatorResponse, MessageResponse
)
from app.services.rule_engine import evaluate_risk
from app.services.account_aggregator import fetch_mock_bank_statement

router = APIRouter()


# ── POST /loans/apply ─────────────────────────────────────────────────────
@router.post("/apply", response_model=LoanApplicationResponse, status_code=201)
def apply_for_loan(
    payload: LoanApplyRequest,
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Submit a new loan application. Rule engine runs automatically."""
    # ── Guard: block new application if borrower already has an active loan ──
    active_loan = db.query(LoanApplication).filter(
        LoanApplication.business_id == borrower.business_id,
        LoanApplication.status == LoanStatus.APPROVED,
    ).first()
    if active_loan:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "ACTIVE_LOAN_EXISTS",
                "message": "You already have an active approved loan. "
                           "Please repay it before applying for a new one.",
                "active_loan_id": str(active_loan.app_id),
                "approved_amount": float(active_loan.requested_amount),
            },
        )

    # Resolve financials: use borrower profile as fallback if not explicitly declared
    declared_turnover = payload.declared_turnover or float(borrower.annual_turnover or 0)
    declared_profit   = payload.declared_profit   or float(borrower.annual_profit   or 0)

    # Run risk engine — returns (score, flags, breakdown)
    risk_score, risk_flags, score_breakdown = evaluate_risk(
        requested_amount=payload.requested_amount,
        tenure_months=payload.tenure_months,
        declared_turnover=declared_turnover,
        declared_profit=declared_profit,
        has_gstin=bool(borrower.gstin),
    )

    loan = LoanApplication(
        business_id=borrower.business_id,
        requested_amount=payload.requested_amount,
        tenure_months=payload.tenure_months,
        purpose=payload.purpose,
        declared_turnover=declared_turnover,
        declared_profit=declared_profit,
        status=LoanStatus.PENDING,
        risk_score=risk_score,
        risk_flags=risk_flags,
        score_breakdown=score_breakdown,
    )
    db.add(loan)
    db.flush()  # get loan.app_id before committing

    # Log the status transition
    log = ApplicationStatusLog(
        app_id=loan.app_id,
        old_status=LoanStatus.DRAFT,
        new_status=LoanStatus.PENDING,
        changed_by="SYSTEM",
        remarks="Application submitted by borrower",
    )
    db.add(log)
    db.commit()
    db.refresh(loan)
    return loan


# ── GET /loans/my ────────────────────────────────────────────────────────
@router.get("/my", response_model=list[LoanApplicationResponse])
def get_my_loans(
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Get all loan applications for the logged-in borrower."""
    loans = db.query(LoanApplication).filter(
        LoanApplication.business_id == borrower.business_id
    ).order_by(LoanApplication.created_at.desc()).all()
    return loans


# ── GET /loans/{app_id}/status ────────────────────────────────────────────
@router.get("/{app_id}/status", response_model=LoanApplicationResponse)
def get_loan_status(
    app_id: UUID,
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Get the current status of a specific loan application."""
    loan = db.query(LoanApplication).filter(
        LoanApplication.app_id == app_id,
        LoanApplication.business_id == borrower.business_id,
    ).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan application not found")
    return loan


# ── POST /loans/account-aggregator/fetch ─────────────────────────────────
@router.post("/account-aggregator/fetch", response_model=AccountAggregatorResponse)
def fetch_bank_statement(
    app_id: UUID,
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Trigger a simulated Account Aggregator data fetch and attach to loan application."""
    loan = db.query(LoanApplication).filter(
        LoanApplication.app_id == app_id,
        LoanApplication.business_id == borrower.business_id,
    ).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan application not found")

    mock_data = fetch_mock_bank_statement(str(borrower.business_id))
    loan.bank_statement_data = mock_data
    db.commit()

    return AccountAggregatorResponse(
        message="Bank statement fetched successfully via Account Aggregator (simulated)",
        data=mock_data,
    )
