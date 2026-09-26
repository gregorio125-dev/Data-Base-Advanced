from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import fetch_one
import logging
from app.routers import books, users, loans, catalog

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("biblioteca")

app = FastAPI(
    title="Sistema de Gestión de Biblioteca API",
    version="1.0.0",
    description="Backend académico de la primera unidad: SQL Server + FastAPI."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(catalog.router)
app.include_router(books.router)
app.include_router(users.router)
app.include_router(loans.router)

@app.get("/")
def root():
    return {
        "sistema": "Sistema de Gestión de Biblioteca",
        "version": "1.0.0",
        "estado": "activo",
        "documentacion": "/docs"
    }

@app.get("/health")
def health():
    try:
        row = fetch_one("SELECT DB_NAME() AS BaseActual, GETDATE() AS FechaServidor")
        return {"api": "OK", "sql_server": "OK", **row}
    except Exception as exc:
        return {"api": "OK", "sql_server": "ERROR", "detalle": str(exc)}
