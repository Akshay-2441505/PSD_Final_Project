from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import auth, loans, admin, dashboard

app = FastAPI(
    title="MSME Digital Lending Sandbox API",
    description="Loan Origination System — Borrower & Admin Portals",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — allow Flutter Web (Admin) and Flutter Mobile (Borrower)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────
app.include_router(auth.router,      prefix="/auth",      tags=["Auth"])
app.include_router(loans.router,     prefix="/loans",     tags=["Loans"])
app.include_router(admin.router,     prefix="/admin",     tags=["Admin"])
app.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "message": "MSME Lending Sandbox API is running 🚀"}
