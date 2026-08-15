USE BibliotecaDB;
GO

INSERT INTO dbo.Categoria (Nombre, Descripcion)
VALUES
('Novela', 'Obras narrativas de ficción'),
('Ciencia', 'Divulgación y ciencias naturales'),
('Tecnología', 'Informática, ingeniería y tecnología'),
('Historia', 'Historia y ciencias sociales'),
('Fantasía', 'Literatura fantástica');
GO

INSERT INTO dbo.Autor (Nombre, Apellido, Nacionalidad)
VALUES
('Gabriel', 'García Márquez', 'Colombiana'),
('Yuval Noah', 'Harari', 'Israelí'),
('Robert C.', 'Martin', 'Estadounidense'),
('J. R. R.', 'Tolkien', 'Británica'),
('Carl', 'Sagan', 'Estadounidense');
GO

INSERT INTO dbo.Usuario (Nombre, Email, Telefono, MaxPrestamos)
VALUES
('Ana Torres', 'ana.torres@biblioteca.local', '3001112233', 3),
('Carlos Pérez', 'carlos.perez@biblioteca.local', '3002223344', 3),
('Laura Gómez', 'laura.gomez@biblioteca.local', '3003334455', 5),
('Administrador Biblioteca', 'admin@biblioteca.local', '3004445566', 10);
GO

INSERT INTO dbo.Libro
    (Titulo, ISBN, AnioPublicacion, Editorial, Descripcion, CategoriaID, AutorID)
VALUES
('Cien años de soledad', '9780307474728', 1967, 'Editorial Sudamericana',
 'Novela emblemática de la literatura latinoamericana.', 1, 1),
('Sapiens', '9780062316097', 2011, 'Harper',
 'Recorrido por la historia de la humanidad.', 4, 2),
('Clean Code', '9780132350884', 2008, 'Prentice Hall',
 'Principios y prácticas para escribir código limpio.', 3, 3),
('El Señor de los Anillos', '9780261102385', 1954, 'Allen & Unwin',
 'Trilogía clásica de fantasía épica.', 5, 4),
('Cosmos', '9780345539434', 1980, 'Random House',
 'Divulgación científica sobre el universo.', 2, 5);
GO

INSERT INTO dbo.LibroAutor (LibroID, AutorID)
SELECT LibroID, AutorID FROM dbo.Libro;
GO

INSERT INTO dbo.Ejemplar (LibroID, CodigoInventario, Estado)
VALUES
(1, 'LIB-001-01', 'Disponible'),
(1, 'LIB-001-02', 'Disponible'),
(2, 'LIB-002-01', 'Disponible'),
(2, 'LIB-002-02', 'Disponible'),
(3, 'LIB-003-01', 'Disponible'),
(3, 'LIB-003-02', 'Disponible'),
(4, 'LIB-004-01', 'Disponible'),
(4, 'LIB-004-02', 'Disponible'),
(5, 'LIB-005-01', 'Disponible'),
(5, 'LIB-005-02', 'Disponible');
GO
