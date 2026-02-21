import sys, json
sys.path.insert(0, '.')
from app.services.account_aggregator import fetch_mock_bank_statement

data = fetch_mock_bank_statement('demo-business-ravi-textiles')

print("=" * 55)
print("  ACCOUNT AGGREGATOR — SIMULATED RESPONSE")
print("=" * 55)
print(f"  Consent ID   : {data['consent_id']}")
print(f"  Bank         : {data['bank']}")
print(f"  Account No   : {data['account_number']}")
print(f"  Period       : {data['period']['from']}  to  {data['period']['to']}")
print()

s = data['summary']
print("  FINANCIAL SUMMARY")
print(f"  Total Credits      : Rs {s['total_credits']:>12,}")
print(f"  Total Debits       : Rs {s['total_debits']:>12,}")
print(f"  Net Cashflow       : Rs {s['net_cashflow']:>12,}")
print(f"  Avg Monthly Bal    : Rs {s['average_monthly_balance']:>12,}")
print()

print(f"  TRANSACTIONS  ({len(data['transactions'])} entries, last 6 months)")
print(f"  {'Date':<12} {'Type':<6} {'Amount':>10}   Description")
print("  " + "-" * 52)

for t in data['transactions']:
    tag = "[CR]" if t['type'] == 'credit' else "[DR]"
    print(f"  {t['date']:<12} {tag:<6} Rs {t['amount']:>8,}   {t['description']}")
