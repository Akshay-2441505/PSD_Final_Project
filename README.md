# MSME Digital Lending Sandbox

A full-stack **Loan Origination System (LOS)** prototype for MSMEs — built with Flutter + FastAPI + PostgreSQL.

## Project Structure

```
PSD_Final_Project/
├── backend/              # FastAPI (Python) REST API + Rule Engine
│   ├── app/
│   │   ├── main.py       # App entry point
│   │   ├── core/         # Config, DB, Security
│   │   ├── models/       # SQLAlchemy ORM models
│   │   ├── schemas/      # Pydantic request/response schemas
│   │   ├── routers/      # API route handlers
│   │   └── services/     # Business logic & rule engine
│   ├── tests/            # pytest test suite
│   ├── requirements.txt
│   └── .env.example      # Copy to .env and fill in values
│
└── frontend/             # Flutter app (Borrower APK + Admin Web)
```

## Backend Setup

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate       # Windows
pip install -r requirements.txt
cp .env.example .env          # Fill in DATABASE_URL and SECRET_KEY
uvicorn app.main:app --reload
```

API docs available at: `http://localhost:8000/docs`

## Tech Stack

| Layer       | Technology                  |
|-------------|-----------------------------|
| Frontend    | Flutter (Dart)              |
| Backend     | FastAPI (Python 3.x)        |
| Database    | PostgreSQL                  |
| Auth        | JWT (python-jose) + bcrypt  |
| DB ORM      | SQLAlchemy 2.0              |
| Deployment  | Render + Vercel + Supabase  |

## Environment

This is a **sandbox simulation** — no real financial transactions occur.
