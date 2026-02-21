"""Quick API smoke test — run with: python test_api.py"""
import httpx, time

BASE = "http://127.0.0.1:8000"
time.sleep(2)

def test(label, r):
    status = "✅" if r.status_code < 400 else "❌"
    print(f"{status} {label}: HTTP {r.status_code}")
    return r

# 1. Health
test("Health Check", httpx.get(f"{BASE}/"))

# 2. Admin login
r = test("Admin Login", httpx.post(f"{BASE}/auth/admin/login",
    json={"email": "arjun.admin@msmelending.com", "password": "Admin@1234"}))
admin_token = r.json().get("access_token", "")
admin_headers = {"Authorization": f"Bearer {admin_token}"}

# 3. Borrower login
r = test("Borrower Login", httpx.post(f"{BASE}/auth/login",
    json={"email": "ravi@ravitextiles.com", "password": "Borrower@1234"}))
borrower_token = r.json().get("access_token", "")
borrower_headers = {"Authorization": f"Bearer {borrower_token}"}

# 4. Admin: list applications
r = test("Admin - List Applications", httpx.get(f"{BASE}/admin/applications", headers=admin_headers))
if r.status_code == 200:
    print(f"   → {len(r.json())} applications found")

# 5. Admin: charts
test("Admin - Expense Chart", httpx.get(f"{BASE}/admin/charts/expenses", headers=admin_headers))
test("Admin - Revenue Chart", httpx.get(f"{BASE}/admin/charts/revenue", headers=admin_headers))

# 6. Borrower: my loans
r = test("Borrower - My Loans", httpx.get(f"{BASE}/loans/my", headers=borrower_headers))
if r.status_code == 200:
    print(f"   → {len(r.json())} loans found")

# 7. Dashboard insights
r = test("Borrower - Dashboard", httpx.get(f"{BASE}/dashboard/insights", headers=borrower_headers))
if r.status_code == 200:
    d = r.json()
    print(f"   → health_score={d['health_score']}, total_apps={d['total_applications']}")

# 8. Borrower: apply for new loan
r = test("Borrower - Apply Loan", httpx.post(f"{BASE}/loans/apply",
    json={
        "requested_amount": 300000,
        "tenure_months": 18,
        "purpose": "WORKING_CAPITAL",
        "declared_turnover": 1500000,
        "declared_profit": 200000
    },
    headers=borrower_headers,
))
if r.status_code == 201:
    loan = r.json()
    print(f"   → risk_score={loan['risk_score']}, flags={loan['risk_flags']}, status={loan['status']}")

print("\n🎉 All tests complete!")
