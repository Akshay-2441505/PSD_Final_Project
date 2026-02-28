"""
profile.py — Borrower profile & financial data endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_borrower
from app.models.models import BorrowerProfile, BorrowerFinancial
from app.schemas.schemas import (
    FinancialDataRequest, FinancialDataResponse, MessageResponse
)

router = APIRouter()


# ── POST /profile/financials — upsert financial data ────────────────────────
@router.post("/financials", response_model=FinancialDataResponse)
def upsert_financials(
    payload: FinancialDataRequest,
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Save or update the borrower's monthly revenue and expense breakdown."""
    existing = db.query(BorrowerFinancial).filter(
        BorrowerFinancial.business_id == borrower.business_id
    ).first()

    if existing:
        existing.monthly_revenue   = [r.model_dump() for r in payload.monthly_revenue]
        existing.expense_breakdown = [e.model_dump() for e in payload.expense_breakdown]
    else:
        record = BorrowerFinancial(
            business_id      = borrower.business_id,
            monthly_revenue  = [r.model_dump() for r in payload.monthly_revenue],
            expense_breakdown= [e.model_dump() for e in payload.expense_breakdown],
        )
        db.add(record)

    db.commit()
    if existing:
        db.refresh(existing)
        return existing
    record_out = db.query(BorrowerFinancial).filter(
        BorrowerFinancial.business_id == borrower.business_id
    ).first()
    return record_out


# ── GET /profile/financials — fetch saved financial data ────────────────────
@router.get("/financials", response_model=FinancialDataResponse)
def get_financials(
    db: Session = Depends(get_db),
    borrower: BorrowerProfile = Depends(get_current_borrower),
):
    """Retrieve the borrower's stored financial data."""
    record = db.query(BorrowerFinancial).filter(
        BorrowerFinancial.business_id == borrower.business_id
    ).first()
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No financial data found. Please complete your financial profile.",
        )
    return record
