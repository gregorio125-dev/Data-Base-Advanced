from fastapi import APIRouter
from app.database import fetch_all

router = APIRouter(prefix="/api", tags=["Catálogos"])

@router.get("/categories")
def list_categories():
    return fetch_all("""
        SELECT CategoriaID, Nombre, Descripcion, Activa
        FROM dbo.Categoria
        WHERE Activa = 1
        ORDER BY Nombre
    """)

@router.get("/authors")
def list_authors():
    return fetch_all("""
        SELECT AutorID, Nombre, Apellido, CONCAT(Nombre, ' ', Apellido) AS NombreCompleto, Nacionalidad
        FROM dbo.Autor
        ORDER BY Nombre, Apellido
    """)
