from fastapi import APIRouter, HTTPException
from app.database import fetch_all, fetch_one, get_connection, clean_sql_error
from app.schemas import BookCreate, BookUpdate

router = APIRouter(prefix="/api/books", tags=["Libros"])

@router.get("")
def list_books():
    return fetch_all("""
        SELECT LibroID, Titulo, ISBN, AnioPublicacion, Editorial,
               Descripcion, CategoriaID, Categoria, AutorID, Autor,
               TotalEjemplares, EjemplaresDisponibles
        FROM dbo.vw_LibrosDisponibles
        ORDER BY Titulo
    """)

@router.get("/{book_id}")
def get_book(book_id: int):
    book = fetch_one("""
        SELECT l.LibroID, l.Titulo, l.ISBN, l.AnioPublicacion,
               l.Editorial, l.Descripcion, l.CategoriaID, c.Nombre AS Categoria,
               l.AutorID, CONCAT(a.Nombre, ' ', a.Apellido) AS Autor
        FROM dbo.Libro l
        INNER JOIN dbo.Categoria c ON c.CategoriaID = l.CategoriaID
        INNER JOIN dbo.Autor a ON a.AutorID = l.AutorID
        WHERE l.LibroID = ?
    """, (book_id,))
    if not book:
        raise HTTPException(404, "Libro no encontrado")
    return book

@router.post("", status_code=201)
def create_book(data: BookCreate):
    """Alta de libro mediante dbo.sp_RegistrarLibro (una única transacción atómica).

    Crea, si hace falta, la categoría y/o el autor nuevos junto con el libro,
    su relación LibroAutor y sus ejemplares. Si algo falla, no se guarda nada.
    """
    cat = data.nueva_categoria
    aut = data.nuevo_autor
    try:
        # autocommit=True: la transacción real (BEGIN/COMMIT/ROLLBACK) vive en el SP.
        with get_connection(autocommit=True) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                EXEC dbo.sp_RegistrarLibro
                    @Titulo=?, @ISBN=?, @AnioPublicacion=?, @Editorial=?, @Descripcion=?,
                    @CantidadEjemplares=?,
                    @CategoriaID=?, @NuevaCategoriaNombre=?, @NuevaCategoriaDescripcion=?,
                    @AutorID=?, @NuevoAutorNombre=?, @NuevoAutorApellido=?, @NuevoAutorNacionalidad=?
            """, (data.titulo, data.isbn, data.anio_publicacion, data.editorial, data.descripcion,
                  data.cantidad_ejemplares,
                  data.categoria_id, cat.nombre if cat else None, cat.descripcion if cat else None,
                  data.autor_id, aut.nombre if aut else None, aut.apellido if aut else None,
                  aut.nacionalidad if aut else None))
            row = cursor.fetchone()
        return {
            "mensaje": "Libro creado correctamente",
            "libro_id": row.LibroID,
            "categoria_id": row.CategoriaID,
            "autor_id": row.AutorID,
            "categoria_creada": bool(row.CategoriaCreada),
            "autor_creado": bool(row.AutorCreado),
        }
    except Exception as exc:
        err_msg = clean_sql_error(exc)
        if "UQ_Libro_ISBN" in str(exc) or "ISBN ya está registrado" in err_msg:
            raise HTTPException(409, "El ISBN ya está registrado para otro libro.")
        raise HTTPException(400, err_msg or "Error al registrar libro.")

@router.put("/{book_id}")
def update_book(book_id: int, data: BookUpdate):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE dbo.Libro
                SET Titulo=?, ISBN=?, AnioPublicacion=?, Editorial=?,
                    Descripcion=?, CategoriaID=?, AutorID=?
                WHERE LibroID=?
            """, (data.titulo, data.isbn, data.anio_publicacion, data.editorial,
                  data.descripcion, data.categoria_id, data.autor_id, book_id))
            if cursor.rowcount == 0:
                raise HTTPException(404, "Libro no encontrado")

            cursor.execute("DELETE FROM dbo.LibroAutor WHERE LibroID=?", (book_id,))
            cursor.execute("INSERT INTO dbo.LibroAutor (LibroID, AutorID) VALUES (?, ?)", (book_id, data.autor_id))
            conn.commit()
        return {"mensaje": "Libro actualizado correctamente"}
    except HTTPException:
        raise
    except Exception as exc:
        err_msg = str(exc)
        if "UQ_Libro_ISBN" in err_msg:
            raise HTTPException(409, "El ISBN ya está registrado para otro libro.")
        if "FK_Libro_Categoria" in err_msg:
            raise HTTPException(400, "La categoría seleccionada no existe.")
        if "FK_Libro_Autor" in err_msg:
            raise HTTPException(400, "El autor seleccionado no existe.")
        raise HTTPException(400, f"Error al actualizar libro: {err_msg}")

@router.delete("/{book_id}")
def delete_book(book_id: int):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT LibroID FROM dbo.Libro WHERE LibroID=?", (book_id,))
            if not cursor.fetchone():
                raise HTTPException(404, "Libro no encontrado")

            cursor.execute("""
                SELECT COUNT(*) FROM dbo.Prestamo p
                INNER JOIN dbo.Ejemplar e ON e.EjemplarID = p.EjemplarID
                WHERE e.LibroID = ?
            """, (book_id,))
            loan_count = cursor.fetchone()[0]
            if loan_count > 0:
                raise HTTPException(409, "No se puede eliminar un libro que tiene historial de préstamos.")

            cursor.execute("DELETE FROM dbo.LibroAutor WHERE LibroID=?", (book_id,))
            cursor.execute("DELETE FROM dbo.Ejemplar WHERE LibroID=?", (book_id,))
            cursor.execute("DELETE FROM dbo.Libro WHERE LibroID=?", (book_id,))
            conn.commit()
        return {"mensaje": "Libro eliminado correctamente"}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(400, f"Error al eliminar libro: {str(exc)}")
