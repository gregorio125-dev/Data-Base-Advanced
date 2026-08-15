import os
from contextlib import contextmanager
import pyodbc
from dotenv import load_dotenv

load_dotenv()

DB_SERVER = os.getenv("DB_SERVER", "localhost")
DB_PORT = os.getenv("DB_PORT", "1433")
DB_NAME = os.getenv("DB_NAME", "BibliotecaDB")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")
DB_TRUST_SERVER_CERTIFICATE = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")

CONNECTION_STRING = (
    f"DRIVER={{{DB_DRIVER}}};"
    f"SERVER={DB_SERVER},{DB_PORT};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USER};"
    f"PWD={DB_PASSWORD};"
    f"TrustServerCertificate={DB_TRUST_SERVER_CERTIFICATE};"
)

@contextmanager
def get_connection():
    conn = pyodbc.connect(CONNECTION_STRING)
    try:
        yield conn
    finally:
        conn.close()

def row_to_dict(cursor, row):
    columns = [column[0] for column in cursor.description]
    return dict(zip(columns, row))

def fetch_all(sql, params=()):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        rows = cursor.fetchall()
        return [row_to_dict(cursor, row) for row in rows]

def fetch_one(sql, params=()):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        row = cursor.fetchone()
        return row_to_dict(cursor, row) if row else None
