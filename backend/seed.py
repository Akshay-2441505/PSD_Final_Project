"""
seed.py — Populate the database with mock data for development & testing.
Usage: python seed.py
"""
import sys, os, json, uuid
from datetime import datetime, timedelta
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.models import (
    BorrowerProfile, LoanApplication, AdminUser,
    ApplicationStatusLog, LoanStatus, LoanPurpose, AdminRole
)

def seed():
    db = SessionLocal()
    print("🌱 Seeding database with mock data...")

    try:
        # ── Admin Users ──────────────────────────────────────────────────
        admins = [
            AdminUser(
                name="Arjun Mehta",
                email="arjun.admin@msmelending.com",
                hashed_password=hash_password("Admin@1234"),
                role=AdminRole.SUPER_ADMIN,
            ),
            AdminUser(
                name="Priya Sharma",
                email="priya.underwriter@msmelending.com",
                hashed_password=hash_password("Admin@1234"),
                role=AdminRole.UNDERWRITER,
            ),
        ]
        db.add_all(admins)
        db.commit()
        print("   ✅ Admin users seeded")

        # ── Borrower Profiles ────────────────────────────────────────────
        borrowers = [
            BorrowerProfile(
                legal_name="Ravi Textiles Pvt Ltd",
                owner_name="Ravi Kumar",
                email="ravi@ravitextiles.com",
                phone="9876543210",
                hashed_password=hash_password("Borrower@1234"),
                gstin="07AABCT1234A1Z5",
                business_type="Manufacturing",
                annual_turnover=2500000.00,
                annual_profit=350000.00,
            ),
            BorrowerProfile(
                legal_name="Sunita Kirana Store",
                owner_name="Sunita Devi",
                email="sunita@kirana.com",
                phone="9123456789",
                hashed_password=hash_password("Borrower@1234"),
                gstin="09ABCDE1234F1Z9",
                business_type="Retail",
                annual_turnover=800000.00,
                annual_profit=120000.00,
            ),
            BorrowerProfile(
                legal_name="TechBuild Solutions",
                owner_name="Aarav Joshi",
                email="aarav@techbuild.in",
                phone="9988776655",
                hashed_password=hash_password("Borrower@1234"),
                gstin=None,
                business_type="IT Services",
                annual_turnover=5000000.00,
                annual_profit=900000.00,
            ),
        ]
        db.add_all(borrowers)
        db.commit()
        print("   ✅ Borrower profiles seeded")

        # ── Mock Bank Statement (Account Aggregator data) ────────────────
        mock_bank_data = {
            "account_number": "XXXX1234",
            "bank": "State Bank of India",
            "transactions": [
                {"date": "2024-12-01", "type": "credit", "amount": 120000, "description": "Client Payment"},
                {"date": "2024-12-05", "type": "debit",  "amount": 45000,  "description": "Raw Material Purchase"},
                {"date": "2024-12-15", "type": "credit", "amount": 85000,  "description": "Invoice Settlement"},
                {"date": "2024-12-22", "type": "debit",  "amount": 20000,  "description": "Utility Bills"},
                {"date": "2025-01-03", "type": "credit", "amount": 200000, "description": "Bulk Order Payment"},
            ],
            "average_monthly_balance": 95000,
            "fetched_at": "2025-01-21T10:30:00Z",
        }

        # ── Loan Applications ────────────────────────────────────────────
        loans = [
            LoanApplication(
                business_id=borrowers[0].business_id,
                requested_amount=500000.00,
                tenure_months=24,
                purpose=LoanPurpose.WORKING_CAPITAL,
                declared_turnover=2500000.00,
                declared_profit=350000.00,
                status=LoanStatus.PENDING,
                risk_score=72,
                risk_flags=["MODERATE_DEBT_RATIO"],
                bank_statement_data=mock_bank_data,
            ),
            LoanApplication(
                business_id=borrowers[1].business_id,
                requested_amount=150000.00,
                tenure_months=12,
                purpose=LoanPurpose.INVENTORY,
                declared_turnover=800000.00,
                declared_profit=120000.00,
                status=LoanStatus.APPROVED,
                risk_score=88,
                risk_flags=[],
                bank_statement_data=mock_bank_data,
                admin_remarks="Strong repayment history. Approved.",
            ),
            LoanApplication(
                business_id=borrowers[2].business_id,
                requested_amount=1200000.00,
                tenure_months=36,
                purpose=LoanPurpose.EXPANSION,
                declared_turnover=5000000.00,
                declared_profit=900000.00,
                status=LoanStatus.UNDER_REVIEW,
                risk_score=61,
                risk_flags=["HIGH_LOAN_AMOUNT", "MISSING_GSTIN"],
                bank_statement_data=mock_bank_data,
            ),
        ]
        db.add_all(loans)
        db.commit()
        print("   ✅ Loan applications seeded")

        # ── Status Logs ──────────────────────────────────────────────────
        logs = [
            ApplicationStatusLog(
                app_id=loans[0].app_id,
                old_status=LoanStatus.DRAFT,
                new_status=LoanStatus.PENDING,
                changed_by="SYSTEM",
                remarks="Application submitted by borrower",
            ),
            ApplicationStatusLog(
                app_id=loans[1].app_id,
                old_status=LoanStatus.PENDING,
                new_status=LoanStatus.APPROVED,
                changed_by="arjun.admin@msmelending.com",
                remarks="Strong repayment history. Approved.",
            ),
            ApplicationStatusLog(
                app_id=loans[2].app_id,
                old_status=LoanStatus.PENDING,
                new_status=LoanStatus.UNDER_REVIEW,
                changed_by="priya.underwriter@msmelending.com",
                remarks="Flagged for manual review - high loan amount",
            ),
        ]
        db.add_all(logs)
        db.commit()
        print("   ✅ Status logs seeded")

        print("\n🎉 Database seeded successfully!")
        print("   Admin login:    arjun.admin@msmelending.com / Admin@1234")
        print("   Borrower login: ravi@ravitextiles.com / Borrower@1234")

    except Exception as e:
        db.rollback()
        print(f"❌ Seeding failed: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed()
