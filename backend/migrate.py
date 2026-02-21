"""
migrate.py — Run this script to create all tables in the Supabase database.
Usage: python migrate.py
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import engine, Base
from app.models.models import (
    BorrowerProfile, LoanApplication, AdminUser, ApplicationStatusLog
)

def run_migration():
    print("🔄 Running database migrations...")
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ All tables created successfully!")
        print("   - borrower_profiles")
        print("   - loan_applications")
        print("   - admin_users")
        print("   - application_status_logs")
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run_migration()
