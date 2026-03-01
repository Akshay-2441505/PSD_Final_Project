"""Quick API test: register, login, save financials — print raw HTTP response."""
import sys, os, requests, json
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

BASE = "http://localhost:8000"
EMAIL = "apitest_fin@example.com"
PASSWORD = "Test@12345"

# 1. Register
r = requests.post(f"{BASE}/auth/register", json={
    "legal_name": "API Test Co", "owner_name": "Tester",
    "email": EMAIL, "phone": "9000000001",
    "password": PASSWORD, "annual_turnover": 1200000, "annual_profit": 200000,
})
print("Register:", r.status_code)

# 2. Login
r = requests.post(f"{BASE}/auth/login", json={"email": EMAIL, "password": PASSWORD})
print("Login:", r.status_code)
token = r.json().get("access_token", "")
headers = {"Authorization": f"Bearer {token}"}

# 3. Save financials
payload = {
    "monthly_revenue": [
        {"month": "Oct 2025", "revenue": 200000},
        {"month": "Nov 2025", "revenue": 210000},
        {"month": "Dec 2025", "revenue": 195000},
        {"month": "Jan 2026", "revenue": 220000},
        {"month": "Feb 2026", "revenue": 230000},
        {"month": "Mar 2026", "revenue": 215000},
    ],
    "expense_breakdown": [
        {"category": "Raw Materials", "percentage": 30.0},
        {"category": "Salaries", "percentage": 25.0},
        {"category": "Rent", "percentage": 20.0},
        {"category": "Utilities", "percentage": 10.0},
        {"category": "Logistics", "percentage": 8.0},
        {"category": "Marketing", "percentage": 7.0},
    ],
}
r = requests.post(f"{BASE}/profile/financials", json=payload, headers=headers)
print("Save Financials:", r.status_code)
print("Response body:", json.dumps(r.json(), indent=2, default=str))
