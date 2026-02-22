"""
account_aggregator.py — Simulates the RBI Account Aggregator (AA) framework.
Returns a mock JSON bank statement for a borrower.

Key design:
- Seeded by business_id → same business always gets consistent, reproducible data
- Transactions span the LAST 6 CALENDAR MONTHS from today (always fresh dates)
- Each month gets 2-4 credits and 3-5 debits with diverse descriptions
"""
import random
import hashlib
from datetime import datetime, date

# ── Description pools ─────────────────────────────────────────────────────
_CREDIT_DESCS = [
    "Client Payment", "Invoice Settlement",
    "Bulk Order Receipt", "GST Refund",
    "Advance Payment", "Export Receivable",
    "Franchise Revenue", "E-commerce Settlement",
]

_DEBIT_DESCS = [
    "Raw Material Purchase",
    "Staff Salary",
    "Rent Payment",
    "Utility Bills",
    "Logistics Cost",
    "Equipment Purchase",
    "Marketing Expense",
    "Software Subscription",
]


def _seeded_rng(business_id: str) -> random.Random:
    """Return a Random() seeded deterministically from business_id."""
    seed = int(hashlib.md5(str(business_id).encode()).hexdigest(), 16) % (2 ** 31)
    return random.Random(seed)


def _month_offset(base: date, months_back: int) -> tuple[int, int]:
    """Return (year, month) for `months_back` months before `base`."""
    total_month = base.year * 12 + (base.month - 1) - months_back
    return total_month // 12, (total_month % 12) + 1


def fetch_mock_bank_statement(business_id: str) -> dict:
    """
    Simulate an Account Aggregator consent + data fetch.
    - Uses TODAY's date so month labels are always current.
    - Seeded by business_id for reproducibility (same business = same chart).
    - Samples debit descriptions without replacement for guaranteed diversity.
    """
    rng   = _seeded_rng(business_id)
    today = date.today()
    transactions = []

    for months_back in range(5, -1, -1):   # 5 months ago → current month
        yr, mo = _month_offset(today, months_back)
        ym     = f"{yr:04d}-{mo:02d}"

        # Slight revenue growth month-over-month
        growth = 1.0 + (5 - months_back) * 0.03

        # Credits (2-4 per month) — sample from pool
        n_credits = rng.randint(2, 4)
        for desc in rng.sample(_CREDIT_DESCS, n_credits):
            transactions.append({
                "date":        f"{ym}-{rng.randint(1, 28):02d}",
                "type":        "credit",
                "amount":      int(rng.randint(30000, 250000) * growth),
                "description": desc,
            })

        # Debits (3-5 per month) — always diverse via sample without replacement
        n_debits = rng.randint(3, 5)
        for desc in rng.sample(_DEBIT_DESCS, n_debits):
            transactions.append({
                "date":        f"{ym}-{rng.randint(1, 28):02d}",
                "type":        "debit",
                "amount":      rng.randint(5000, 80000),
                "description": desc,
            })

    transactions.sort(key=lambda x: x["date"])

    total_credits = sum(t["amount"] for t in transactions if t["type"] == "credit")
    total_debits  = sum(t["amount"] for t in transactions if t["type"] == "debit")
    yr0, mo0 = _month_offset(today, 5)

    return {
        "consent_id":     f"AA-CONSENT-{str(business_id)[:8].upper()}",
        "account_number": f"XXXX{rng.randint(1000, 9999)}",
        "bank":           rng.choice([
            "State Bank of India", "HDFC Bank",
            "ICICI Bank", "Axis Bank", "Kotak Bank"
        ]),
        "period": {
            "from": f"{yr0:04d}-{mo0:02d}-01",
            "to":   today.strftime("%Y-%m-%d"),
        },
        "summary": {
            "total_credits":           total_credits,
            "total_debits":            total_debits,
            "net_cashflow":            total_credits - total_debits,
            "average_monthly_balance": rng.randint(50000, 300000),
        },
        "transactions": transactions,
        "fetched_at":   datetime.utcnow().isoformat() + "Z",
    }
