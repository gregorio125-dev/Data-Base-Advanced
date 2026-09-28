import os
import re
from contextlib import contextmanager
import pyodbc
from dotenv import load_dotenv

load_dotenv()

DB_SERVER = os.getenv("DB_SERVER", "localhost")
DB_PORT = os.getenv("DB_PORT", "").strip()
DB_NAME = os.getenv("DB_NAME", "BibliotecaDB")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")
DB_TRUST_SERVER_CERTIFICATE = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")
DB_TRUSTED_CONNECTION = os.getenv("DB_TRUSTED_CONNECTION", "yes").strip().lower()

server_part = f"{DB_SERVER},{DB_PORT}" if DB_PORT else DB_SERVER
auth_part = "Trusted_Connection=yes;" if DB_TRUSTED_CONNECTION in ("yes", "true", "1") else f"UID={DB_USER};PWD={DB_PASSWORD};"

CONNECTION_STRING = (
    f"DRIVER={{{DB_DRIVER}}};"
    f"SERVER={server_part};"
    f"DATABASE={DB_NAME};"
    f"{auth_part}"
    f"TrustServerCertificate={DB_TRUST_SERVER_CERTIFICATE};"
)

@contextmanager
def get_connection(autocommit=False):
    # autocommit=True se usa cuando la transacción la maneja el propio
    # procedimiento almacenado (BEGIN TRANSACTION / COMMIT dentro del SP).
    conn = pyodbc.connect(CONNECTION_STRING, autocommit=autocommit)
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

def clean_sql_error(exc):
    """Extrae solo el mensaje legible de un error de SQL Server (THROW / RAISERROR)."""
    msg = str(exc)
    if "[SQL Server]" in msg:
        msg = msg.split("[SQL Server]")[-1].strip()
    msg = re.sub(r"(\s*\(\d+\))*\s*\(SQL[A-Za-z]+\)['\"]?\)?\s*$", "", msg)
    return msg.strip()
