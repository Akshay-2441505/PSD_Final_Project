"""
dependencies.py — Reusable FastAPI dependency injectors for auth guards.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.models import BorrowerProfile, AdminUser

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_borrower(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> BorrowerProfile:
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "borrower":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    borrower = db.query(BorrowerProfile).filter(
        BorrowerProfile.email == payload.get("sub")
    ).first()
    if not borrower:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Borrower not found")
    return borrower


def get_current_admin(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> AdminUser:
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "admin":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    admin = db.query(AdminUser).filter(
        AdminUser.email == payload.get("sub")
    ).first()
    if not admin or not admin.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin account inactive or not found")
    return admin
