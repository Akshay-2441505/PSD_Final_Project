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
    LoanApplication, BorrowerProfile, ApplicationStatusLog, AdminUser
)
from app.schemas.schemas import (
    AdminApplicationListItem, AdminApplicationDetail,
    AdminDecisionRequest, MessageResponse, ChartDataResponse
)

router = APIRouter()


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
    """Full detail of one loan application including borrower profile and bank statement."""
    result = db.query(LoanApplication, BorrowerProfile).join(
        BorrowerProfile, LoanApplication.business_id == BorrowerProfile.business_id
    ).filter(LoanApplication.app_id == app_id).first()

    if not result:
        raise HTTPException(status_code=404, detail="Application not found")

    loan, borrower = result
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

    old_status = loan.status
    loan.status = payload.decision
    loan.admin_remarks = payload.remarks

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


# ── GET /admin/charts/expenses ────────────────────────────────────────────
@router.get("/charts/expenses", response_model=ChartDataResponse)
def get_expense_chart(admin: AdminUser = Depends(get_current_admin)):
    """Simulated expense breakdown data for the admin pie chart."""
    return ChartDataResponse(
        labels=["Raw Materials", "Salaries", "Rent", "Utilities", "Logistics", "Marketing"],
        data=[35.0, 25.0, 15.0, 8.0, 10.0, 7.0],
    )


# ── GET /admin/charts/revenue ─────────────────────────────────────────────
@router.get("/charts/revenue", response_model=ChartDataResponse)
def get_revenue_chart(admin: AdminUser = Depends(get_current_admin)):
    """Simulated monthly revenue trend for the admin line graph (last 6 months)."""
    return ChartDataResponse(
        labels=["Sep", "Oct", "Nov", "Dec", "Jan", "Feb"],
        data=[820000, 950000, 870000, 1100000, 1050000, 1230000],
    )
