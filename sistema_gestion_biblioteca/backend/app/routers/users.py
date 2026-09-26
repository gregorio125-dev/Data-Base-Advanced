from fastapi import APIRouter, HTTPException
from app.database import fetch_all, fetch_one, get_connection
from app.schemas import UserCreate, UserUpdate

router = APIRouter(prefix="/api/users", tags=["Usuarios"])

@router.get("")
def list_users():
    return fetch_all("""
        SELECT UsuarioID, Nombre, Email, Telefono, MaxPrestamos, Activo, FechaRegistro
        FROM dbo.Usuario
        ORDER BY Nombre
    """)

@router.get("/{user_id}")
def get_user(user_id: int):
    user = fetch_one("""
        SELECT UsuarioID, Nombre, Email, Telefono, MaxPrestamos, Activo, FechaRegistro
        FROM dbo.Usuario
        WHERE UsuarioID=?
    """, (user_id,))
    if not user:
        raise HTTPException(404, "Usuario no encontrado")
    return user

@router.post("", status_code=201)
def create_user(data: UserCreate):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO dbo.Usuario (Nombre, Email, Telefono, MaxPrestamos)
                OUTPUT INSERTED.UsuarioID
                VALUES (?, ?, ?, ?)
            """, (data.nombre, str(data.email), data.telefono, data.max_prestamos))
            user_id = cursor.fetchone()[0]
            conn.commit()
        return {"mensaje": "Usuario creado correctamente", "usuario_id": user_id}
    except Exception as exc:
        if "UQ_Usuario_Email" in str(exc):
            raise HTTPException(409, "El correo ya está registrado")
        raise

@router.put("/{user_id}")
def update_user(user_id: int, data: UserUpdate):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE dbo.Usuario
                SET Nombre=?, Email=?, Telefono=?, MaxPrestamos=?, Activo=?
                WHERE UsuarioID=?
            """, (data.nombre, str(data.email), data.telefono, data.max_prestamos,
                  data.activo, user_id))
            if cursor.rowcount == 0:
                raise HTTPException(404, "Usuario no encontrado")
            conn.commit()
        return {"mensaje": "Usuario actualizado correctamente"}
    except HTTPException:
        raise
    except Exception as exc:
        if "UQ_Usuario_Email" in str(exc):
            raise HTTPException(409, "El correo ya está registrado para otro usuario")
        raise HTTPException(400, f"Error al actualizar usuario: {str(exc)}")

@router.delete("/{user_id}")
def delete_user(user_id: int):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM dbo.Prestamo
            WHERE UsuarioID=? AND Estado='Activo'
        """, (user_id,))
        if cursor.fetchone()[0]:
            raise HTTPException(409, "No se puede desactivar/eliminar un usuario con préstamos activos.")

        cursor.execute("""
            UPDATE dbo.Usuario SET Activo=0 WHERE UsuarioID=?
        """, (user_id,))
        if cursor.rowcount == 0:
            raise HTTPException(404, "Usuario no encontrado")
        conn.commit()
    return {"mensaje": "Usuario desactivado correctamente"}
