import enum
from sqlalchemy import (
    Column, String, Numeric, Integer, Text,
    DateTime, ForeignKey, Enum as SAEnum
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


# ── Enums ──────────────────────────────────────────────────────────────────

class LoanStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    PENDING = "PENDING"
    UNDER_REVIEW = "UNDER_REVIEW"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    MORE_INFO_REQUESTED = "MORE_INFO_REQUESTED"

class LoanPurpose(str, enum.Enum):
    WORKING_CAPITAL = "WORKING_CAPITAL"
    EQUIPMENT_PURCHASE = "EQUIPMENT_PURCHASE"
    INVENTORY = "INVENTORY"
    EXPANSION = "EXPANSION"
    OTHER = "OTHER"

class AdminRole(str, enum.Enum):
    UNDERWRITER = "UNDERWRITER"
    SUPER_ADMIN = "SUPER_ADMIN"


# ── Table 1: borrower_profiles ─────────────────────────────────────────────

class BorrowerProfile(Base):
    __tablename__ = "borrower_profiles"

    business_id     = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    legal_name      = Column(String(255), nullable=False)
    owner_name      = Column(String(255), nullable=False)
    email           = Column(String(255), unique=True, nullable=False, index=True)
    phone           = Column(String(20), nullable=False)
    hashed_password = Column(Text, nullable=False)
    gstin           = Column(String(15), unique=True, nullable=True)
    business_type   = Column(String(100), nullable=True)
    annual_turnover = Column(Numeric(15, 2), nullable=True)
    annual_profit   = Column(Numeric(15, 2), nullable=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), onupdate=func.now())


# ── Table 2: loan_applications ─────────────────────────────────────────────

class LoanApplication(Base):
    __tablename__ = "loan_applications"

    app_id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id         = Column(UUID(as_uuid=True), ForeignKey("borrower_profiles.business_id"), nullable=False, index=True)
    requested_amount    = Column(Numeric(15, 2), nullable=False)
    tenure_months       = Column(Integer, nullable=False)
    purpose             = Column(SAEnum(LoanPurpose), nullable=False)
    declared_turnover   = Column(Numeric(15, 2), nullable=True)
    declared_profit     = Column(Numeric(15, 2), nullable=True)
    status              = Column(SAEnum(LoanStatus), nullable=False, default=LoanStatus.DRAFT)
    risk_score          = Column(Integer, nullable=True)           # 0-100
    risk_flags          = Column(JSONB, nullable=True)             # e.g. ["HIGH_DEBT_RATIO"]
    score_breakdown     = Column(JSONB, nullable=True)             # per-rule explanation list
    bank_statement_data = Column(JSONB, nullable=True)             # Mock Account Aggregator dump
    admin_remarks       = Column(Text, nullable=True)
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), onupdate=func.now())


# ── Table 3: admin_users ───────────────────────────────────────────────────

class AdminUser(Base):
    __tablename__ = "admin_users"

    admin_id        = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name            = Column(String(255), nullable=False)
    email           = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(Text, nullable=False)
    role            = Column(SAEnum(AdminRole), nullable=False, default=AdminRole.UNDERWRITER)
    is_active       = Column(Integer, default=1)  # 1 = active, 0 = disabled
    created_at      = Column(DateTime(timezone=True), server_default=func.now())


# ── Table 4: application_status_logs ──────────────────────────────────────

class ApplicationStatusLog(Base):
    __tablename__ = "application_status_logs"

    log_id      = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    app_id      = Column(UUID(as_uuid=True), ForeignKey("loan_applications.app_id"), nullable=False, index=True)
    old_status  = Column(SAEnum(LoanStatus), nullable=True)
    new_status  = Column(SAEnum(LoanStatus), nullable=False)
    changed_by  = Column(String(255), nullable=True)   # admin email or "SYSTEM"
    remarks     = Column(Text, nullable=True)
    timestamp   = Column(DateTime(timezone=True), server_default=func.now())
