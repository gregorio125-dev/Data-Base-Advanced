from datetime import date
from decimal import Decimal
from pydantic import BaseModel, Field, EmailStr, ConfigDict

class BookCreate(BaseModel):
    titulo: str = Field(min_length=1, max_length=200)
    isbn: str = Field(min_length=10, max_length=20)
    anio_publicacion: int = Field(ge=1000, le=2100)
    categoria_id: int
    autor_id: int
    editorial: str | None = Field(default=None, max_length=150)
    descripcion: str | None = None
    cantidad_ejemplares: int = Field(default=1, ge=1, le=100)

class BookUpdate(BaseModel):
    titulo: str = Field(min_length=1, max_length=200)
    isbn: str = Field(min_length=10, max_length=20)
    anio_publicacion: int = Field(ge=1000, le=2100)
    categoria_id: int
    autor_id: int
    editorial: str | None = Field(default=None, max_length=150)
    descripcion: str | None = None

class UserCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=120)
    email: str = Field(min_length=5, max_length=180, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    telefono: str | None = Field(default=None, max_length=30)
    max_prestamos: int = Field(default=3, ge=1, le=20)

class UserUpdate(UserCreate):
    activo: bool = True

class LoanCreate(BaseModel):
    usuario_id: int
    ejemplar_id: int
    dias_prestamo: int = Field(default=14, ge=1, le=60)

class Message(BaseModel):
    mensaje: str
