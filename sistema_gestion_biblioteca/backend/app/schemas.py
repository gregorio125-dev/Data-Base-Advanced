from datetime import date
from decimal import Decimal
from pydantic import BaseModel, Field, EmailStr, ConfigDict, model_validator

class NuevaCategoria(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    nombre: str = Field(min_length=2, max_length=100)
    descripcion: str | None = Field(default=None, max_length=300)

class NuevoAutor(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    nombre: str = Field(min_length=1, max_length=100)
    apellido: str = Field(min_length=1, max_length=100)
    nacionalidad: str | None = Field(default=None, max_length=80)

class BookCreate(BaseModel):
    titulo: str = Field(min_length=1, max_length=200)
    isbn: str = Field(min_length=10, max_length=20)
    anio_publicacion: int = Field(ge=1000, le=2100)
    # Categoría y autor: se envía el ID de uno existente O los datos de uno nuevo.
    categoria_id: int | None = None
    nueva_categoria: NuevaCategoria | None = None
    autor_id: int | None = None
    nuevo_autor: NuevoAutor | None = None
    editorial: str | None = Field(default=None, max_length=150)
    descripcion: str | None = None
    cantidad_ejemplares: int = Field(default=1, ge=1, le=100)

    @model_validator(mode="after")
    def validar_categoria_y_autor(self):
        if (self.categoria_id is None) == (self.nueva_categoria is None):
            raise ValueError("Seleccione una categoría existente o registre una nueva (no ambas).")
        if (self.autor_id is None) == (self.nuevo_autor is None):
            raise ValueError("Seleccione un autor existente o registre uno nuevo (no ambos).")
        return self

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
