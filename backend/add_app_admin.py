"""add_app_admin.py — Add the admin@lendingapp.com user expected by the Flutter admin app."""
import sys, os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.models import AdminUser, AdminRole

db = SessionLocal()
try:
    existing = db.query(AdminUser).filter(AdminUser.email == "admin@lendingapp.com").first()
    if existing:
        print("admin@lendingapp.com already exists")
    else:
        admin = AdminUser(
            name="App Admin",
            email="admin@lendingapp.com",
            hashed_password=hash_password("Admin@123"),
            role=AdminRole.SUPER_ADMIN,
        )
        db.add(admin)
        db.commit()
        print("✅ admin@lendingapp.com / Admin@123 created")
finally:
    db.close()
