"""
rule_engine.py — Mock risk scoring engine for loan applications.
Evaluates financial data and assigns a risk score (0-100) + flags.
Higher score = lower risk = better chance of approval.
"""
from typing import Tuple, List


def evaluate_risk(
    requested_amount: float,
    tenure_months: int,
    declared_turnover: float,
    declared_profit: float,
    has_gstin: bool,
) -> Tuple[int, List[str]]:
    """
    Returns (risk_score, risk_flags).
    Score: 0–100 (higher = safer to lend)
    """
    score = 100
    flags = []

    # ── Rule 1: Debt-to-Turnover Ratio ───────────────────────────────────
    if declared_turnover and declared_turnover > 0:
        debt_ratio = requested_amount / declared_turnover
        if debt_ratio > 0.5:
            score -= 25
            flags.append("HIGH_DEBT_RATIO")
        elif debt_ratio > 0.3:
            score -= 10
            flags.append("MODERATE_DEBT_RATIO")
    else:
        score -= 20
        flags.append("NO_TURNOVER_DECLARED")

    # ── Rule 2: Profitability ─────────────────────────────────────────────
    if declared_profit is not None:
        if declared_profit <= 0:
            score -= 30
            flags.append("LOSS_MAKING_BUSINESS")
        elif declared_turnover and declared_turnover > 0:
            profit_margin = declared_profit / declared_turnover
            if profit_margin < 0.05:
                score -= 15
                flags.append("LOW_PROFIT_MARGIN")
    else:
        score -= 10
        flags.append("NO_PROFIT_DECLARED")

    # ── Rule 3: Loan Amount Ceiling ───────────────────────────────────────
    if requested_amount > 1_000_000:
        score -= 15
        flags.append("HIGH_LOAN_AMOUNT")

    # ── Rule 4: GSTIN Missing ─────────────────────────────────────────────
    if not has_gstin:
        score -= 10
        flags.append("MISSING_GSTIN")

    # ── Rule 5: Tenure ────────────────────────────────────────────────────
    if tenure_months > 48:
        score -= 5
        flags.append("LONG_TENURE")

    # Clamp score between 0 and 100
    score = max(0, min(100, score))
    return score, flags
