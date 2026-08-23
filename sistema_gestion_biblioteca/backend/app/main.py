from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import fetch_one
from app.routers import books, users, loans

app = FastAPI(
    title="Sistema de Gestión de Biblioteca API",
    version="1.0.0",
    description="Backend académico de la primera unidad: SQL Server + FastAPI."
)

import traceback

@app.exception_handler(Exception)
async def debug_exception_handler(request, exc):
    with open(r"C:\Users\manue\Desktop\error.log", "w", encoding="utf-8") as f:
        f.write(traceback.format_exc())
    raise exc

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/test-error")
def test_error():
    raise Exception("Esto es una prueba de error")
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
