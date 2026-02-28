"""
rule_engine.py — Risk scoring engine for loan applications.
Evaluates financial data and assigns a risk score (0-100) + human-readable breakdown.
Higher score = lower risk = better chance of approval.
"""
from typing import Tuple, List, Dict


def evaluate_risk(
    requested_amount: float,
    tenure_months: int,
    declared_turnover: float,
    declared_profit: float,
    has_gstin: bool,
) -> Tuple[int, List[str], List[Dict]]:
    """
    Returns (risk_score, risk_flags, score_breakdown).
    Score: 0–100 (higher = safer to lend).
    score_breakdown: list of dicts explaining each deduction.
    """
    score = 100
    flags = []
    breakdown = []

    # ── Rule 1: Debt-to-Turnover Ratio ───────────────────────────────────
    if declared_turnover and declared_turnover > 0:
        debt_ratio = requested_amount / declared_turnover
        pct = round(debt_ratio * 100, 1)
        if debt_ratio > 0.5:
            score -= 25
            flags.append("HIGH_DEBT_RATIO")
            breakdown.append({
                "rule": "Debt-to-Turnover Ratio",
                "impact": -25,
                "detail": f"Loan amount is {pct}% of annual turnover (above 50% threshold). "
                          f"This indicates high borrowing relative to business size.",
                "severity": "high",
            })
        elif debt_ratio > 0.3:
            score -= 10
            flags.append("MODERATE_DEBT_RATIO")
            breakdown.append({
                "rule": "Debt-to-Turnover Ratio",
                "impact": -10,
                "detail": f"Loan amount is {pct}% of annual turnover (between 30–50%). "
                          f"Moderate borrowing — manageable but worth monitoring.",
                "severity": "medium",
            })
        else:
            breakdown.append({
                "rule": "Debt-to-Turnover Ratio",
                "impact": 0,
                "detail": f"Loan amount is {pct}% of annual turnover (below 30%). Healthy ratio.",
                "severity": "ok",
            })
    else:
        score -= 20
        flags.append("NO_TURNOVER_DECLARED")
        breakdown.append({
            "rule": "Debt-to-Turnover Ratio",
            "impact": -20,
            "detail": "No annual turnover was declared. Cannot assess debt-to-income ratio.",
            "severity": "high",
        })

    # ── Rule 2: Profitability ─────────────────────────────────────────────
    if declared_profit is not None:
        if declared_profit <= 0:
            score -= 30
            flags.append("LOSS_MAKING_BUSINESS")
            breakdown.append({
                "rule": "Profitability",
                "impact": -30,
                "detail": f"Business reported a loss (profit: ₹{declared_profit:,.0f}). "
                          f"Loss-making businesses carry significantly higher default risk.",
                "severity": "high",
            })
        elif declared_turnover and declared_turnover > 0:
            profit_margin = declared_profit / declared_turnover
            margin_pct = round(profit_margin * 100, 1)
            if profit_margin < 0.05:
                score -= 15
                flags.append("LOW_PROFIT_MARGIN")
                breakdown.append({
                    "rule": "Profitability",
                    "impact": -15,
                    "detail": f"Profit margin is {margin_pct}% (below 5% minimum threshold). "
                              f"Thin margins reduce repayment capacity.",
                    "severity": "medium",
                })
            else:
                breakdown.append({
                    "rule": "Profitability",
                    "impact": 0,
                    "detail": f"Profit margin is {margin_pct}%. Business is profitable.",
                    "severity": "ok",
                })
    else:
        score -= 10
        flags.append("NO_PROFIT_DECLARED")
        breakdown.append({
            "rule": "Profitability",
            "impact": -10,
            "detail": "No annual profit was declared. Profitability cannot be confirmed.",
            "severity": "medium",
        })

    # ── Rule 3: Loan Amount Ceiling ───────────────────────────────────────
    if requested_amount > 1_000_000:
        score -= 15
        flags.append("HIGH_LOAN_AMOUNT")
        breakdown.append({
            "rule": "Loan Amount",
            "impact": -15,
            "detail": f"Requested amount ₹{requested_amount:,.0f} exceeds ₹10L threshold. "
                      f"Large loans carry higher default exposure.",
            "severity": "medium",
        })
    else:
        breakdown.append({
            "rule": "Loan Amount",
            "impact": 0,
            "detail": f"Requested amount ₹{requested_amount:,.0f} is within the ₹10L threshold.",
            "severity": "ok",
        })

    # ── Rule 4: GSTIN Missing ─────────────────────────────────────────────
    if not has_gstin:
        score -= 10
        flags.append("MISSING_GSTIN")
        breakdown.append({
            "rule": "GST Registration",
            "impact": -10,
            "detail": "No GSTIN provided. GST registration demonstrates formal business status "
                      "and provides a verifiable transaction history.",
            "severity": "medium",
        })
    else:
        breakdown.append({
            "rule": "GST Registration",
            "impact": 0,
            "detail": "GSTIN is on file. Business is GST-registered.",
            "severity": "ok",
        })

    # ── Rule 5: Tenure ────────────────────────────────────────────────────
    if tenure_months > 48:
        score -= 5
        flags.append("LONG_TENURE")
        breakdown.append({
            "rule": "Loan Tenure",
            "impact": -5,
            "detail": f"Tenure of {tenure_months} months exceeds 48 months. "
                      f"Longer tenures increase exposure to economic uncertainty.",
            "severity": "low",
        })
    else:
        breakdown.append({
            "rule": "Loan Tenure",
            "impact": 0,
            "detail": f"Tenure of {tenure_months} months is within acceptable range.",
            "severity": "ok",
        })

    score = max(0, min(100, score))
    return score, flags, breakdown
