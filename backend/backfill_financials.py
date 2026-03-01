"""
backfill_financials.py
Update existing loan_applications that have declared_turnover=0 or NULL
by copying annual_turnover / annual_profit from borrower_profiles.
"""
from app.core.database import engine
from sqlalchemy import text

UPDATE_SQL = """
UPDATE loan_applications la
SET
    declared_turnover = COALESCE(NULLIF(la.declared_turnover, 0), bp.annual_turnover),
    declared_profit   = COALESCE(NULLIF(la.declared_profit,   0), bp.annual_profit)
FROM borrower_profiles bp
WHERE la.business_id = bp.business_id
  AND (la.declared_turnover IS NULL OR la.declared_turnover = 0
       OR la.declared_profit IS NULL OR la.declared_profit = 0);
"""

with engine.begin() as conn:
    result = conn.execute(text(UPDATE_SQL))
    print(f"✅ Updated {result.rowcount} loan application(s) with borrower profile financials.")
