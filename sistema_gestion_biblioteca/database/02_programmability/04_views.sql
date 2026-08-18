USE BibliotecaDB;
GO

CREATE OR ALTER VIEW dbo.vw_LibrosDisponibles
AS
SELECT
    l.LibroID,
    l.Titulo,
    l.ISBN,
    l.AnioPublicacion,
    l.Editorial,
    l.Descripcion,
    l.CategoriaID,
    c.Nombre AS Categoria,
    l.AutorID,
    CONCAT(a.Nombre, ' ', a.Apellido) AS Autor,
    COUNT(e.EjemplarID) AS TotalEjemplares,
    SUM(CASE WHEN e.Estado = 'Disponible' THEN 1 ELSE 0 END) AS EjemplaresDisponibles
FROM dbo.Libro l
INNER JOIN dbo.Categoria c ON c.CategoriaID = l.CategoriaID
INNER JOIN dbo.Autor a ON a.AutorID = l.AutorID
LEFT JOIN dbo.Ejemplar e ON e.LibroID = l.LibroID
GROUP BY
    l.LibroID, l.Titulo, l.ISBN, l.AnioPublicacion,
    l.Editorial, l.Descripcion, l.CategoriaID, c.Nombre,
    l.AutorID, a.Nombre, a.Apellido;
GO

CREATE OR ALTER VIEW dbo.vw_PrestamosActivos
AS
SELECT
    p.PrestamoID,
    u.UsuarioID,
    u.Nombre AS Usuario,
    e.EjemplarID,
    e.CodigoInventario,
    l.LibroID,
    l.Titulo,
    p.FechaPrestamo,
    p.FechaVencimiento,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), p.FechaVencimiento) AS DiasParaVencer
FROM dbo.Prestamo p
INNER JOIN dbo.Usuario u ON u.UsuarioID = p.UsuarioID
INNER JOIN dbo.Ejemplar e ON e.EjemplarID = p.EjemplarID
INNER JOIN dbo.Libro l ON l.LibroID = e.LibroID
WHERE p.Estado = 'Activo';
GO
