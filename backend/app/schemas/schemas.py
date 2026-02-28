from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List, Any
from uuid import UUID
from datetime import datetime
from app.models.models import LoanStatus, LoanPurpose, AdminRole


# ══════════════════════════════════════════════════════════════
#  AUTH SCHEMAS
# ══════════════════════════════════════════════════════════════

class BorrowerRegisterRequest(BaseModel):
    legal_name: str = Field(..., min_length=2, max_length=255)
    owner_name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=6)
    gstin: Optional[str] = Field(None, max_length=15)
    business_type: Optional[str] = None
    annual_turnover: Optional[float] = Field(None, ge=0, description="Annual business turnover in INR")
    annual_profit: Optional[float] = Field(None, description="Annual net profit in INR")


class BorrowerLoginRequest(BaseModel):
    email: EmailStr
    password: str

class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str

class BorrowerProfileResponse(BaseModel):
    business_id: UUID
    legal_name: str
    owner_name: str
    email: str
    phone: str
    gstin: Optional[str]
    business_type: Optional[str]
    annual_turnover: Optional[float]
    annual_profit: Optional[float]
    created_at: Optional[datetime]

    class Config:
        from_attributes = True


# ══════════════════════════════════════════════════════════════
#  LOAN SCHEMAS
# ══════════════════════════════════════════════════════════════

class LoanApplyRequest(BaseModel):
    requested_amount: float = Field(..., gt=0, le=10_000_000)
    tenure_months: int   = Field(..., ge=3, le=60)
    purpose: LoanPurpose
    declared_turnover: Optional[float] = Field(None, ge=0)
    declared_profit: Optional[float]   = Field(None)

class LoanApplicationResponse(BaseModel):
    app_id: UUID
    business_id: UUID
    requested_amount: float
    tenure_months: int
    purpose: LoanPurpose
    declared_turnover: Optional[float]
    declared_profit: Optional[float]
    status: LoanStatus
    risk_score: Optional[int]
    risk_flags: Optional[List[str]]
    score_breakdown: Optional[List[Any]]
    admin_remarks: Optional[str]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class AccountAggregatorResponse(BaseModel):
    message: str
    data: Any


# ══════════════════════════════════════════════════════════════
#  ADMIN SCHEMAS
# ══════════════════════════════════════════════════════════════

class AdminDecisionRequest(BaseModel):
    decision: LoanStatus = Field(..., description="APPROVED | REJECTED | MORE_INFO_REQUESTED")
    remarks: Optional[str] = Field(None, max_length=1000)

    @field_validator("decision")
    @classmethod
    def decision_must_be_terminal(cls, v):
        allowed = {LoanStatus.APPROVED, LoanStatus.REJECTED, LoanStatus.MORE_INFO_REQUESTED}
        if v not in allowed:
            raise ValueError("Decision must be APPROVED, REJECTED, or MORE_INFO_REQUESTED")
        return v

class AdminApplicationListItem(BaseModel):
    app_id: UUID
    business_id: UUID
    legal_name: str
    requested_amount: float
    tenure_months: int
    purpose: LoanPurpose
    status: LoanStatus
    risk_score: Optional[int]
    risk_flags: Optional[List[str]]
    created_at: Optional[datetime]

class AdminApplicationDetail(LoanApplicationResponse):
    legal_name: str
    owner_name: str
    email: str
    phone: str
    gstin: Optional[str]
    annual_turnover: Optional[float]
    annual_profit: Optional[float]
    bank_statement_data: Optional[Any]


# ══════════════════════════════════════════════════════════════
#  DASHBOARD / CHARTS SCHEMAS
# ══════════════════════════════════════════════════════════════

class DashboardInsightsResponse(BaseModel):
    total_applications: int
    approved_amount: float
    pending_count: int
    next_emi_due: Optional[str]
    health_score: int     # 0–100
    monthly_revenue: List[dict]
    expense_breakdown: List[dict]

class ChartDataResponse(BaseModel):
    labels: List[str]
    data: List[float]


# ══════════════════════════════════════════════════════════════
#  GENERIC
# ══════════════════════════════════════════════════════════════

class MessageResponse(BaseModel):
    message: str
