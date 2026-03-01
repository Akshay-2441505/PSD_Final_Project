"""
test_rule_engine.py — Unit tests for the risk scoring rule engine.
These tests have NO database dependencies — pure Python logic.
"""
import pytest
from app.services.rule_engine import evaluate_risk


class TestRuleEngineBaseline:
    """Score starts at 100 with perfect inputs."""

    def test_perfect_profile_gives_high_score(self):
        score, flags, breakdown = evaluate_risk(
            requested_amount=100_000,     # 5% of turnover — low debt ratio
            tenure_months=12,
            declared_turnover=2_000_000,
            declared_profit=400_000,      # 20% margin — excellent
            has_gstin=True,
        )
        assert score >= 90
        assert flags == []

    def test_returns_three_values(self):
        result = evaluate_risk(100_000, 12, 2_000_000, 400_000, True)
        assert len(result) == 3

    def test_score_is_clamped_0_to_100(self):
        # Force every penalty
        score, _, _ = evaluate_risk(
            requested_amount=5_000_000,  # huge loan
            tenure_months=60,            # long tenure
            declared_turnover=0,         # no turnover
            declared_profit=-100_000,    # loss-making
            has_gstin=False,
        )
        assert 0 <= score <= 100

    def test_breakdown_has_same_count_as_rules(self):
        _, _, breakdown = evaluate_risk(100_000, 12, 2_000_000, 400_000, True)
        # 5 rules = 5 breakdown entries
        assert len(breakdown) == 5

    def test_breakdown_items_have_required_keys(self):
        _, _, breakdown = evaluate_risk(100_000, 12, 2_000_000, 400_000, True)
        for item in breakdown:
            assert "rule"     in item
            assert "impact"   in item
            assert "detail"   in item
            assert "severity" in item


class TestDebtToTurnoverRule:
    """Rule 1: HIGH_DEBT_RATIO triggers when loan > 50% of turnover."""

    def test_high_debt_ratio_deducts_25(self):
        # Loan = 60% of turnover → -25
        score, flags, _ = evaluate_risk(600_000, 12, 1_000_000, 100_000, True)
        assert "HIGH_DEBT_RATIO" in flags
        # With only this penalty + moderate margin (~10%), score should be around 65
        assert score <= 75

    def test_moderate_debt_ratio_deducts_10(self):
        # Loan = 35% of turnover → -10 (MODERATE_DEBT_RATIO)
        score, flags, _ = evaluate_risk(350_000, 12, 1_000_000, 200_000, True)
        assert "MODERATE_DEBT_RATIO" in flags

    def test_low_debt_ratio_no_flag(self):
        # Loan = 10% of turnover → no flag
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, True)
        assert "HIGH_DEBT_RATIO" not in flags
        assert "MODERATE_DEBT_RATIO" not in flags

    def test_zero_turnover_deducts_20(self):
        score, flags, _ = evaluate_risk(100_000, 12, 0, 50_000, True)
        assert "NO_TURNOVER_DECLARED" in flags
        assert score <= 80


class TestProfitabilityRule:
    """Rule 2: Low/negative profit triggers flags."""

    def test_loss_making_deducts_30(self):
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, -50_000, True)
        assert "LOSS_MAKING_BUSINESS" in flags

    def test_low_margin_deducts_15(self):
        # Profit margin = 3% (below 5% threshold)
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 30_000, True)
        assert "LOW_PROFIT_MARGIN" in flags

    def test_good_margin_no_flag(self):
        # Profit margin = 20%
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, True)
        assert "LOW_PROFIT_MARGIN" not in flags
        assert "LOSS_MAKING_BUSINESS" not in flags

    def test_null_profit_deducts_10(self):
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, None, True)
        assert "NO_PROFIT_DECLARED" in flags


class TestLoanAmountRule:
    """Rule 3: Loans > ₹10L get penalised."""

    def test_above_10L_deducts_15(self):
        _, flags, _ = evaluate_risk(1_500_000, 12, 5_000_000, 1_000_000, True)
        assert "HIGH_LOAN_AMOUNT" in flags

    def test_exactly_10L_no_flag(self):
        _, flags, _ = evaluate_risk(1_000_000, 12, 5_000_000, 1_000_000, True)
        assert "HIGH_LOAN_AMOUNT" not in flags

    def test_below_10L_no_flag(self):
        _, flags, _ = evaluate_risk(500_000, 12, 5_000_000, 1_000_000, True)
        assert "HIGH_LOAN_AMOUNT" not in flags


class TestGSTINRule:
    """Rule 4: Missing GSTIN deducts 10 points."""

    def test_missing_gstin_deducts_10(self):
        score_with, _, _  = evaluate_risk(100_000, 12, 1_000_000, 200_000, True)
        score_without, _, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, False)
        assert score_without == score_with - 10

    def test_missing_gstin_adds_flag(self):
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, False)
        assert "MISSING_GSTIN" in flags

    def test_with_gstin_no_flag(self):
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, True)
        assert "MISSING_GSTIN" not in flags


class TestTenureRule:
    """Rule 5: Tenure > 48 months adds LONG_TENURE flag."""

    def test_long_tenure_adds_flag(self):
        _, flags, _ = evaluate_risk(100_000, 60, 1_000_000, 200_000, True)
        assert "LONG_TENURE" in flags

    def test_exactly_48_months_no_flag(self):
        _, flags, _ = evaluate_risk(100_000, 48, 1_000_000, 200_000, True)
        assert "LONG_TENURE" not in flags

    def test_short_tenure_no_flag(self):
        _, flags, _ = evaluate_risk(100_000, 12, 1_000_000, 200_000, True)
        assert "LONG_TENURE" not in flags


class TestAmortization:
    """Unit tests for the EMI / amortization calculator."""

    def test_emi_formula(self):
        from app.services.amortization import calculate_emi
        emi = calculate_emi(100_000, 0.01, 12)
        # Standard formula: 100000 * 0.01 * 1.01^12 / (1.01^12 - 1)
        assert 8800 < emi < 9000  # ~₹8,885/month

    def test_schedule_length_matches_tenure(self):
        from app.services.amortization import generate_schedule
        from datetime import datetime
        schedule = generate_schedule(100_000, 12, datetime.utcnow())
        assert len(schedule) == 12

    def test_schedule_balance_approaches_zero(self):
        from app.services.amortization import generate_schedule
        from datetime import datetime
        schedule = generate_schedule(100_000, 12, datetime.utcnow())
        assert schedule[-1]["balance"] < 1  # last balance ≈ 0 (rounding)

    def test_schedule_items_have_required_keys(self):
        from app.services.amortization import generate_schedule
        from datetime import datetime
        schedule = generate_schedule(50_000, 6, datetime.utcnow())
        required = {"installment", "due_date", "emi", "principal", "interest", "balance", "status"}
        for row in schedule:
            assert required.issubset(row.keys())

    def test_total_repayment_is_positive(self):
        from app.services.amortization import total_repayment
        total = total_repayment(100_000, 12)
        assert total > 100_000  # must be more than principal due to interest
