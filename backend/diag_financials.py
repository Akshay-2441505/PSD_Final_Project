"""Diagnostic: show loan declared financials vs borrower profile financials."""
from app.core.database import engine
from sqlalchemy import text

SQL = """
SELECT
    la.app_id,
    la.declared_turnover,
    la.declared_profit,
    bp.annual_turnover,
    bp.annual_profit,
    bp.email
FROM loan_applications la
JOIN borrower_profiles bp ON la.business_id = bp.business_id
ORDER BY la.created_at DESC
LIMIT 10;
"""

with engine.connect() as conn:
    rows = conn.execute(text(SQL)).fetchall()
    print(f"{'app_id':<10} {'decl_turn':>12} {'decl_prof':>12} {'ann_turn':>12} {'ann_prof':>10} {'email'}")
    print("-"*80)
    for r in rows:
        print(f"{str(r[0])[:8]:<10} {str(r[1]):>12} {str(r[2]):>12} {str(r[3]):>12} {str(r[4]):>10} {r[5]}")
