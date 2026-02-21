"""
auth.py — Borrower registration + login. Admin login.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.models.models import BorrowerProfile, AdminUser
from app.schemas.schemas import (
    BorrowerRegisterRequest, BorrowerLoginRequest, AdminLoginRequest,
    TokenResponse, BorrowerProfileResponse, MessageResponse
)

router = APIRouter()


# ── POST /auth/register ───────────────────────────────────────────────────
@router.post("/register", response_model=BorrowerProfileResponse, status_code=201)
def register_borrower(payload: BorrowerRegisterRequest, db: Session = Depends(get_db)):
    """Register a new MSME borrower account."""
    existing = db.query(BorrowerProfile).filter(BorrowerProfile.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    borrower = BorrowerProfile(
        legal_name=payload.legal_name,
        owner_name=payload.owner_name,
        email=payload.email,
        phone=payload.phone,
        hashed_password=hash_password(payload.password),
        gstin=payload.gstin,
        business_type=payload.business_type,
    )
    db.add(borrower)
    db.commit()
    db.refresh(borrower)
    return borrower


# ── POST /auth/login ──────────────────────────────────────────────────────
@router.post("/login", response_model=TokenResponse)
def login_borrower(payload: BorrowerLoginRequest, db: Session = Depends(get_db)):
    """Borrower login — returns JWT access token."""
    borrower = db.query(BorrowerProfile).filter(BorrowerProfile.email == payload.email).first()
    if not borrower or not verify_password(payload.password, borrower.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token({"sub": borrower.email, "role": "borrower", "id": str(borrower.business_id)})
    return TokenResponse(access_token=token, role="borrower")


# ── POST /auth/admin/login ────────────────────────────────────────────────
@router.post("/admin/login", response_model=TokenResponse)
def login_admin(payload: AdminLoginRequest, db: Session = Depends(get_db)):
    """Admin login — returns JWT access token with admin role."""
    admin = db.query(AdminUser).filter(AdminUser.email == payload.email).first()
    if not admin or not verify_password(payload.password, admin.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not admin.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    token = create_access_token({"sub": admin.email, "role": "admin", "id": str(admin.admin_id)})
    return TokenResponse(access_token=token, role=admin.role.value)
