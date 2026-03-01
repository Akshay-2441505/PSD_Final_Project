from app.core.database import engine, Base
from sqlalchemy import text

with engine.connect() as c:
    rows = c.execute(text(
        "SELECT table_schema, table_name FROM information_schema.tables "
        "WHERE table_schema IN ('public','test_schema') "
        "ORDER BY table_schema, table_name"
    )).fetchall()
    if rows:
        for r in rows:
            print(f"{r[0]} | {r[1]}")
    else:
        print("NO TABLES FOUND IN public or test_schema — tables were dropped!")
