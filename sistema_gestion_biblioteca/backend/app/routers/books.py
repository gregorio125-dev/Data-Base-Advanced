from fastapi import APIRouter, HTTPException
from app.database import fetch_all, fetch_one, get_connection
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
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO dbo.Libro
                (Titulo, ISBN, AnioPublicacion, Editorial, Descripcion, CategoriaID, AutorID)
            OUTPUT INSERTED.LibroID
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (data.titulo, data.isbn, data.anio_publicacion, data.editorial,
              data.descripcion, data.categoria_id, data.autor_id))
        book_id = cursor.fetchone()[0]

        for numero in range(1, data.cantidad_ejemplares + 1):
            cursor.execute("""
                INSERT INTO dbo.Ejemplar (LibroID, CodigoInventario, Estado)
                VALUES (?, CONCAT('AUTO-', ?, '-', ?), 'Disponible')
            """, (book_id, book_id, numero))
        conn.commit()
    return {"mensaje": "Libro creado correctamente", "libro_id": book_id}

@router.put("/{book_id}")
def update_book(book_id: int, data: BookUpdate):
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
        conn.commit()
    return {"mensaje": "Libro actualizado correctamente"}

@router.delete("/{book_id}")
def delete_book(book_id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM dbo.Ejemplar WHERE LibroID=?", (book_id,))
        count = cursor.fetchone()[0]
        if count:
            raise HTTPException(409, "No se puede eliminar un libro que tiene ejemplares. Retire los ejemplares primero.")
        cursor.execute("DELETE FROM dbo.Libro WHERE LibroID=?", (book_id,))
        if cursor.rowcount == 0:
            raise HTTPException(404, "Libro no encontrado")
        conn.commit()
    return {"mensaje": "Libro eliminado correctamente"}
