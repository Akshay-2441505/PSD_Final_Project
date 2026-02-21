"""
account_aggregator.py — Simulates the RBI Account Aggregator (AA) framework.
Returns a mock JSON bank statement for a borrower.
"""
from datetime import datetime, timedelta
import random


def fetch_mock_bank_statement(business_id: str) -> dict:
    """
    Simulate an Account Aggregator consent + data fetch.
    Returns a realistic mock bank statement JSON.
    """
    today = datetime.today()
    transactions = []

    # Generate 6 months of mock transactions
    for i in range(6, 0, -1):
        month_date = today - timedelta(days=30 * i)
        month_str = month_date.strftime("%Y-%m")

        # Credits (income)
        for _ in range(random.randint(2, 4)):
            transactions.append({
                "date": f"{month_str}-{random.randint(1, 28):02d}",
                "type": "credit",
                "amount": random.randint(30000, 250000),
                "description": random.choice([
                    "Client Payment", "Invoice Settlement",
                    "Bulk Order Receipt", "GST Refund", "Advance Payment"
                ]),
            })

        # Debits (expenses)
        for _ in range(random.randint(2, 5)):
            transactions.append({
                "date": f"{month_str}-{random.randint(1, 28):02d}",
                "type": "debit",
                "amount": random.randint(5000, 80000),
                "description": random.choice([
                    "Raw Material Purchase", "Utility Bills", "Staff Salary",
                    "Rent Payment", "Equipment Purchase", "Logistics Cost"
                ]),
            })

    # Sort by date
    transactions.sort(key=lambda x: x["date"])

    # Compute summary
    total_credits = sum(t["amount"] for t in transactions if t["type"] == "credit")
    total_debits  = sum(t["amount"] for t in transactions if t["type"] == "debit")

    return {
        "consent_id": f"AA-CONSENT-{business_id[:8].upper()}",
        "account_number": f"XXXX{random.randint(1000, 9999)}",
        "bank": random.choice(["State Bank of India", "HDFC Bank", "ICICI Bank", "Axis Bank", "Kotak Bank"]),
        "period": {
            "from": (today - timedelta(days=180)).strftime("%Y-%m-%d"),
            "to": today.strftime("%Y-%m-%d"),
        },
        "summary": {
            "total_credits": total_credits,
            "total_debits": total_debits,
            "net_cashflow": total_credits - total_debits,
            "average_monthly_balance": random.randint(50000, 300000),
        },
        "transactions": transactions,
        "fetched_at": datetime.utcnow().isoformat() + "Z",
    }
