USE BibliotecaDB;
GO

IF OBJECT_ID('dbo.Multa', 'U') IS NOT NULL DROP TABLE dbo.Multa;
IF OBJECT_ID('dbo.Prestamo', 'U') IS NOT NULL DROP TABLE dbo.Prestamo;
IF OBJECT_ID('dbo.Ejemplar', 'U') IS NOT NULL DROP TABLE dbo.Ejemplar;
IF OBJECT_ID('dbo.LibroAutor', 'U') IS NOT NULL DROP TABLE dbo.LibroAutor;
IF OBJECT_ID('dbo.Libro', 'U') IS NOT NULL DROP TABLE dbo.Libro;
IF OBJECT_ID('dbo.Autor', 'U') IS NOT NULL DROP TABLE dbo.Autor;
IF OBJECT_ID('dbo.Categoria', 'U') IS NOT NULL DROP TABLE dbo.Categoria;
IF OBJECT_ID('dbo.Usuario', 'U') IS NOT NULL DROP TABLE dbo.Usuario;
GO

CREATE TABLE dbo.Categoria (
    CategoriaID INT IDENTITY(1,1) CONSTRAINT PK_Categoria PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL CONSTRAINT UQ_Categoria_Nombre UNIQUE,
    Descripcion NVARCHAR(300) NULL,
    Activa BIT NOT NULL CONSTRAINT DF_Categoria_Activa DEFAULT 1
);
GO

CREATE TABLE dbo.Autor (
    AutorID INT IDENTITY(1,1) CONSTRAINT PK_Autor PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Nacionalidad NVARCHAR(80) NULL,
    FechaNacimiento DATE NULL
);
GO

CREATE TABLE dbo.Usuario (
    UsuarioID INT IDENTITY(1,1) CONSTRAINT PK_Usuario PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Email NVARCHAR(180) NOT NULL CONSTRAINT UQ_Usuario_Email UNIQUE,
    Telefono NVARCHAR(30) NULL,
    MaxPrestamos INT NOT NULL CONSTRAINT DF_Usuario_MaxPrestamos DEFAULT 3,
    Activo BIT NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT 1,
    FechaRegistro DATE NOT NULL CONSTRAINT DF_Usuario_FechaRegistro DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT CK_Usuario_MaxPrestamos CHECK (MaxPrestamos BETWEEN 1 AND 20)
);
GO

CREATE TABLE dbo.Libro (
    LibroID INT IDENTITY(1,1) CONSTRAINT PK_Libro PRIMARY KEY,
    Titulo NVARCHAR(200) NOT NULL,
    ISBN NVARCHAR(20) NOT NULL CONSTRAINT UQ_Libro_ISBN UNIQUE,
    AnioPublicacion INT NOT NULL,
    Editorial NVARCHAR(150) NULL,
    Descripcion NVARCHAR(1000) NULL,
    CategoriaID INT NOT NULL,
    AutorID INT NOT NULL,
    CONSTRAINT FK_Libro_Categoria FOREIGN KEY (CategoriaID) REFERENCES dbo.Categoria(CategoriaID),
    CONSTRAINT FK_Libro_Autor FOREIGN KEY (AutorID) REFERENCES dbo.Autor(AutorID),
    CONSTRAINT CK_Libro_Anio CHECK (AnioPublicacion BETWEEN 1000 AND 2100)
);
GO

CREATE TABLE dbo.LibroAutor (
    LibroID INT NOT NULL,
    AutorID INT NOT NULL,
    CONSTRAINT PK_LibroAutor PRIMARY KEY (LibroID, AutorID),
    CONSTRAINT FK_LibroAutor_Libro FOREIGN KEY (LibroID) REFERENCES dbo.Libro(LibroID),
    CONSTRAINT FK_LibroAutor_Autor FOREIGN KEY (AutorID) REFERENCES dbo.Autor(AutorID)
);
GO

CREATE TABLE dbo.Ejemplar (
    EjemplarID INT IDENTITY(1,1) CONSTRAINT PK_Ejemplar PRIMARY KEY,
    LibroID INT NOT NULL,
    CodigoInventario NVARCHAR(50) NOT NULL CONSTRAINT UQ_Ejemplar_Codigo UNIQUE,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Ejemplar_Estado DEFAULT 'Disponible',
    FechaAlta DATE NOT NULL CONSTRAINT DF_Ejemplar_FechaAlta DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Ejemplar_Libro FOREIGN KEY (LibroID) REFERENCES dbo.Libro(LibroID),
    CONSTRAINT CK_Ejemplar_Estado CHECK (Estado IN ('Disponible','Prestado','Mantenimiento','Baja'))
);
GO

CREATE TABLE dbo.Prestamo (
    PrestamoID INT IDENTITY(1,1) CONSTRAINT PK_Prestamo PRIMARY KEY,
    UsuarioID INT NOT NULL,
    EjemplarID INT NOT NULL,
    FechaPrestamo DATE NOT NULL CONSTRAINT DF_Prestamo_FechaPrestamo DEFAULT CAST(GETDATE() AS DATE),
    FechaVencimiento DATE NOT NULL,
    FechaDevolucion DATE NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Prestamo_Estado DEFAULT 'Activo',
    CONSTRAINT FK_Prestamo_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID),
    CONSTRAINT FK_Prestamo_Ejemplar FOREIGN KEY (EjemplarID) REFERENCES dbo.Ejemplar(EjemplarID),
    CONSTRAINT CK_Prestamo_Estado CHECK (Estado IN ('Activo','Devuelto','Perdido')),
    CONSTRAINT CK_Prestamo_Fechas CHECK (FechaVencimiento >= FechaPrestamo),
    CONSTRAINT CK_Prestamo_Devolucion CHECK (FechaDevolucion IS NULL OR FechaDevolucion >= FechaPrestamo)
);
GO

CREATE TABLE dbo.Multa (
    MultaID INT IDENTITY(1,1) CONSTRAINT PK_Multa PRIMARY KEY,
    PrestamoID INT NOT NULL CONSTRAINT UQ_Multa_Prestamo UNIQUE,
    DiasRetraso INT NOT NULL,
    Valor DECIMAL(10,2) NOT NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Multa_Estado DEFAULT 'Pendiente',
    FechaGeneracion DATE NOT NULL CONSTRAINT DF_Multa_Fecha DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Multa_Prestamo FOREIGN KEY (PrestamoID) REFERENCES dbo.Prestamo(PrestamoID),
    CONSTRAINT CK_Multa_Dias CHECK (DiasRetraso >= 0),
    CONSTRAINT CK_Multa_Valor CHECK (Valor >= 0),
    CONSTRAINT CK_Multa_Estado CHECK (Estado IN ('Pendiente','Pagada','Anulada'))
);
GO

CREATE INDEX IX_Libro_Categoria ON dbo.Libro(CategoriaID);
CREATE INDEX IX_Ejemplar_Libro_Estado ON dbo.Ejemplar(LibroID, Estado);
CREATE INDEX IX_Prestamo_Usuario_Estado ON dbo.Prestamo(UsuarioID, Estado);
CREATE INDEX IX_Prestamo_FechaVencimiento ON dbo.Prestamo(FechaVencimiento, Estado);
GO
