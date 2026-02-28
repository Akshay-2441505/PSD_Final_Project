"""
amortization.py — EMI & repayment schedule calculator.
Used when admin approves a loan to generate the full month-by-month schedule.
"""
from datetime import datetime, timedelta
from typing import List, Dict


MONTHLY_INTEREST_RATE = 0.01   # 1% per month = 12% per annum (fixed for all loans)
ANNUAL_INTEREST_RATE  = 0.12   # 12% p.a.


def calculate_emi(principal: float, monthly_rate: float, tenure_months: int) -> float:
    """Standard reducing-balance EMI formula: P × r × (1+r)^n / ((1+r)^n − 1)"""
    if tenure_months == 0:
        return principal
    factor = (1 + monthly_rate) ** tenure_months
    return round(principal * monthly_rate * factor / (factor - 1), 2)


def generate_schedule(
    principal: float,
    tenure_months: int,
    start_date: datetime,
    monthly_rate: float = MONTHLY_INTEREST_RATE,
) -> List[Dict]:
    """
    Generate a full amortization schedule.
    Returns a list of dicts, one per EMI installment:
      {
        "installment": 1,
        "due_date": "2025-04-01",
        "emi": 9040.0,
        "principal": 7040.0,
        "interest": 2000.0,
        "balance": 92960.0,
        "status": "PENDING"   # PENDING | PAID | OVERDUE
      }
    """
    emi = calculate_emi(principal, monthly_rate, tenure_months)
    balance = principal
    schedule = []

    for i in range(1, tenure_months + 1):
        interest   = round(balance * monthly_rate, 2)
        principal_component = round(emi - interest, 2)
        balance    = round(balance - principal_component, 2)
        due_date   = start_date + timedelta(days=30 * i)

        schedule.append({
            "installment": i,
            "due_date":    due_date.strftime("%Y-%m-%d"),
            "emi":         emi,
            "principal":   principal_component,
            "interest":    interest,
            "balance":     max(0, balance),
            "status":      "PENDING",
        })

    return schedule


def total_repayment(principal: float, tenure_months: int) -> float:
    emi = calculate_emi(principal, MONTHLY_INTEREST_RATE, tenure_months)
    return round(emi * tenure_months, 2)
