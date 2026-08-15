from fastapi import APIRouter, HTTPException
from app.database import fetch_all, fetch_one, get_connection
from app.schemas import LoanCreate

router = APIRouter(prefix="/api/loans", tags=["Préstamos"])

@router.get("/available")
def available_copies():
    return fetch_all("""
        SELECT e.EjemplarID, e.CodigoInventario, l.LibroID, l.Titulo
        FROM dbo.Ejemplar e
        INNER JOIN dbo.Libro l ON l.LibroID=e.LibroID
        WHERE e.Estado='Disponible'
        ORDER BY l.Titulo, e.CodigoInventario
    """)

@router.get("/overdue")
def overdue_loans():
    return fetch_all("""
        WITH PrestamosVencidos AS (
            SELECT p.PrestamoID, p.UsuarioID, u.Nombre AS Usuario,
                   p.EjemplarID, l.Titulo, p.FechaPrestamo,
                   p.FechaVencimiento,
                   DATEDIFF(DAY, p.FechaVencimiento, CAST(GETDATE() AS DATE)) AS DiasRetraso
            FROM dbo.Prestamo p
            INNER JOIN dbo.Usuario u ON u.UsuarioID=p.UsuarioID
            INNER JOIN dbo.Ejemplar e ON e.EjemplarID=p.EjemplarID
            INNER JOIN dbo.Libro l ON l.LibroID=e.LibroID
            WHERE p.Estado='Activo'
              AND p.FechaVencimiento < CAST(GETDATE() AS DATE)
        )
        SELECT * FROM PrestamosVencidos
        ORDER BY DiasRetraso DESC
    """)

@router.post("", status_code=201)
def create_loan(data: LoanCreate):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                EXEC dbo.sp_RegistrarPrestamo ?, ?, ?
            """, (data.usuario_id, data.ejemplar_id, data.dias_prestamo))
            row = cursor.fetchone()
            conn.commit()
            if row:
                return {
                    "mensaje": "Préstamo registrado correctamente",
                    "prestamo_id": row[0],
                    "fecha_prestamo": row[1],
                    "fecha_vencimiento": row[2]
                }
            return {"mensaje": "Préstamo registrado correctamente"}
    except Exception as exc:
        raise HTTPException(400, str(exc))

@router.put("/{loan_id}/return")
def return_loan(loan_id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE dbo.Prestamo
            SET FechaDevolucion=CAST(GETDATE() AS DATE), Estado='Devuelto'
            WHERE PrestamoID=? AND Estado='Activo'
        """, (loan_id,))
        if cursor.rowcount == 0:
            raise HTTPException(404, "Préstamo activo no encontrado")
        conn.commit()

    loan = fetch_one("""
        SELECT p.PrestamoID, p.FechaDevolucion, p.Estado,
               ISNULL(m.MultaID, 0) AS MultaID,
               ISNULL(m.Valor, 0) AS Multa
        FROM dbo.Prestamo p
        LEFT JOIN dbo.Multa m ON m.PrestamoID=p.PrestamoID
        WHERE p.PrestamoID=?
    """, (loan_id,))
    return {"mensaje": "Devolución registrada correctamente", **loan}
