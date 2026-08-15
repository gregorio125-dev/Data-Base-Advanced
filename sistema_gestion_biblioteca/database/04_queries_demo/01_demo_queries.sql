USE BibliotecaDB;
GO

-- 1. Catálogo y disponibilidad
SELECT * FROM dbo.vw_LibrosDisponibles ORDER BY Titulo;
GO

-- 2. Subconsulta: usuarios que tienen al menos un préstamo activo
SELECT UsuarioID, Nombre, Email
FROM dbo.Usuario
WHERE UsuarioID IN (
    SELECT UsuarioID
    FROM dbo.Prestamo
    WHERE Estado = 'Activo'
);
GO

-- 3. CTE: préstamos vencidos
WITH PrestamosVencidos AS (
    SELECT
        p.PrestamoID,
        u.Nombre AS Usuario,
        l.Titulo,
        p.FechaVencimiento,
        DATEDIFF(DAY, p.FechaVencimiento, CAST(GETDATE() AS DATE)) AS DiasRetraso
    FROM dbo.Prestamo p
    INNER JOIN dbo.Usuario u ON u.UsuarioID = p.UsuarioID
    INNER JOIN dbo.Ejemplar e ON e.EjemplarID = p.EjemplarID
    INNER JOIN dbo.Libro l ON l.LibroID = e.LibroID
    WHERE p.Estado = 'Activo'
      AND p.FechaVencimiento < CAST(GETDATE() AS DATE)
)
SELECT * FROM PrestamosVencidos
ORDER BY DiasRetraso DESC;
GO

-- 4. Probar función de multas
SELECT
    Dias,
    dbo.fn_CalcularMulta(Dias) AS Multa
FROM (VALUES (0),(1),(5),(6),(15),(16),(30)) AS X(Dias);
GO

-- 5. Registrar un préstamo de prueba
EXEC dbo.sp_RegistrarPrestamo
    @UsuarioID = 1,
    @EjemplarID = 1,
    @DiasPrestamo = 14;
GO

-- 6. Consultar préstamos activos
SELECT * FROM dbo.vw_PrestamosActivos;
GO

-- 7. Probar devolución normal
-- UPDATE dbo.Prestamo
-- SET FechaDevolucion = CAST(GETDATE() AS DATE), Estado = 'Devuelto'
-- WHERE PrestamoID = 1;
GO

-- 8. Probar trigger de multa manualmente con un préstamo activo:
-- UPDATE dbo.Prestamo
-- SET FechaVencimiento = DATEADD(DAY, -10, CAST(GETDATE() AS DATE))
-- WHERE PrestamoID = 1 AND Estado = 'Activo';
-- UPDATE dbo.Prestamo
-- SET FechaDevolucion = CAST(GETDATE() AS DATE), Estado = 'Devuelto'
-- WHERE PrestamoID = 1;
-- SELECT * FROM dbo.Multa;
GO
