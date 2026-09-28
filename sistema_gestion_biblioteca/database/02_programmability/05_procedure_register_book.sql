USE BibliotecaDB;
GO

/*
  sp_RegistrarLibro
  ---------------------------------------------------------------------------
  Alta completa de un libro en UNA sola transacción atómica.

  Toca hasta 5 tablas: Categoria (opcional), Autor (opcional), Libro,
  LibroAutor y Ejemplar. Si cualquier paso falla (ISBN duplicado, categoría
  inexistente, error de restricción, etc.) se revierte TODO: no quedan autores
  ni categorías "huérfanos" creados a medias.

  Cómo indicar la categoría y el autor (exactamente una opción de cada par):
    - Existente : @CategoriaID / @AutorID
    - Nueva     : @NuevaCategoriaNombre / @NuevoAutorNombre + @NuevoAutorApellido
                  (si ya existe una con el mismo nombre, se reutiliza en lugar
                   de duplicarla)

  Conceptos del PDF de transacciones que aplica:
    - BEGIN / COMMIT / ROLLBACK dentro de TRY...CATCH
    - SET XACT_ABORT ON
    - ROLLBACK defensivo verificando @@TRANCOUNT
    - Transacción corta: las validaciones de parámetros se hacen ANTES de abrirla
    - Aislamiento: UPDLOCK + HOLDLOCK (equivale a SERIALIZABLE en esas lecturas)
      para evitar el fenómeno de "phantom read" cuando dos bibliotecarios
      registran a la vez el mismo autor, categoría o ISBN.
*/
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarLibro
    @Titulo                    NVARCHAR(200),
    @ISBN                      NVARCHAR(20),
    @AnioPublicacion           INT,
    @Editorial                 NVARCHAR(150)  = NULL,
    @Descripcion               NVARCHAR(1000) = NULL,
    @CantidadEjemplares        INT            = 1,
    -- Categoría: existente O nueva
    @CategoriaID               INT            = NULL,
    @NuevaCategoriaNombre      NVARCHAR(100)  = NULL,
    @NuevaCategoriaDescripcion NVARCHAR(300)  = NULL,
    -- Autor: existente O nuevo
    @AutorID                   INT            = NULL,
    @NuevoAutorNombre          NVARCHAR(100)  = NULL,
    @NuevoAutorApellido        NVARCHAR(100)  = NULL,
    @NuevoAutorNacionalidad    NVARCHAR(80)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LibroID         INT;
    DECLARE @CategoriaCreada BIT = 0;
    DECLARE @AutorCreado     BIT = 0;

    BEGIN TRY
        ------------------------------------------------------------------
        -- 1) Validaciones baratas ANTES de abrir la transacción
        ------------------------------------------------------------------
        SET @Titulo                 = LTRIM(RTRIM(@Titulo));
        SET @ISBN                   = LTRIM(RTRIM(@ISBN));
        SET @NuevaCategoriaNombre   = NULLIF(LTRIM(RTRIM(@NuevaCategoriaNombre)), '');
        SET @NuevoAutorNombre       = NULLIF(LTRIM(RTRIM(@NuevoAutorNombre)), '');
        SET @NuevoAutorApellido     = NULLIF(LTRIM(RTRIM(@NuevoAutorApellido)), '');

        IF ISNULL(@Titulo, '') = '' OR ISNULL(@ISBN, '') = ''
            THROW 50010, 'El título y el ISBN son obligatorios.', 1;

        IF @CantidadEjemplares NOT BETWEEN 1 AND 100
            THROW 50011, 'La cantidad de ejemplares debe estar entre 1 y 100.', 1;

        IF (@CategoriaID IS NULL AND @NuevaCategoriaNombre IS NULL)
           OR (@CategoriaID IS NOT NULL AND @NuevaCategoriaNombre IS NOT NULL)
            THROW 50012, 'Indique una categoría existente o los datos de una categoría nueva, pero no ambas.', 1;

        IF (@AutorID IS NULL AND (@NuevoAutorNombre IS NULL OR @NuevoAutorApellido IS NULL))
           OR (@AutorID IS NOT NULL AND (@NuevoAutorNombre IS NOT NULL OR @NuevoAutorApellido IS NOT NULL))
            THROW 50013, 'Indique un autor existente o nombre y apellido de un autor nuevo, pero no ambos.', 1;

        ------------------------------------------------------------------
        -- 2) Transacción: todo o nada
        ------------------------------------------------------------------
        BEGIN TRANSACTION;

        -- ISBN duplicado (con bloqueo para que otra sesión no lo inserte en medio)
        IF EXISTS (SELECT 1 FROM dbo.Libro WITH (UPDLOCK, HOLDLOCK) WHERE ISBN = @ISBN)
            THROW 50014, 'El ISBN ya está registrado para otro libro.', 1;

        -- Categoría
        IF @CategoriaID IS NULL
        BEGIN
            SELECT @CategoriaID = CategoriaID
            FROM dbo.Categoria WITH (UPDLOCK, HOLDLOCK)
            WHERE Nombre = @NuevaCategoriaNombre;

            IF @CategoriaID IS NULL
            BEGIN
                INSERT INTO dbo.Categoria (Nombre, Descripcion)
                VALUES (@NuevaCategoriaNombre, NULLIF(LTRIM(RTRIM(@NuevaCategoriaDescripcion)), ''));

                SET @CategoriaID = SCOPE_IDENTITY();
                SET @CategoriaCreada = 1;
            END
            ELSE
                -- Existía pero estaba desactivada: se reactiva para que aparezca en el catálogo
                UPDATE dbo.Categoria SET Activa = 1 WHERE CategoriaID = @CategoriaID AND Activa = 0;
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE CategoriaID = @CategoriaID)
            THROW 50015, 'La categoría seleccionada no existe.', 1;

        -- Autor
        IF @AutorID IS NULL
        BEGIN
            SELECT @AutorID = AutorID
            FROM dbo.Autor WITH (UPDLOCK, HOLDLOCK)
            WHERE Nombre = @NuevoAutorNombre AND Apellido = @NuevoAutorApellido;

            IF @AutorID IS NULL
            BEGIN
                INSERT INTO dbo.Autor (Nombre, Apellido, Nacionalidad)
                VALUES (@NuevoAutorNombre, @NuevoAutorApellido, NULLIF(LTRIM(RTRIM(@NuevoAutorNacionalidad)), ''));

                SET @AutorID = SCOPE_IDENTITY();
                SET @AutorCreado = 1;
            END
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Autor WHERE AutorID = @AutorID)
            THROW 50016, 'El autor seleccionado no existe.', 1;

        -- Libro + relación N:M + ejemplares
        INSERT INTO dbo.Libro
            (Titulo, ISBN, AnioPublicacion, Editorial, Descripcion, CategoriaID, AutorID)
        VALUES
            (@Titulo, @ISBN, @AnioPublicacion, @Editorial, @Descripcion, @CategoriaID, @AutorID);

        SET @LibroID = SCOPE_IDENTITY();

        INSERT INTO dbo.LibroAutor (LibroID, AutorID)
        VALUES (@LibroID, @AutorID);

        INSERT INTO dbo.Ejemplar (LibroID, CodigoInventario, Estado)
        SELECT @LibroID,
               CONCAT('AUTO-', @LibroID, '-', n.Numero),
               'Disponible'
        FROM (
            SELECT TOP (@CantidadEjemplares)
                   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Numero
            FROM sys.all_objects
        ) AS n;

        COMMIT TRANSACTION;

        SELECT
            @LibroID         AS LibroID,
            @CategoriaID     AS CategoriaID,
            @AutorID         AS AutorID,
            @CategoriaCreada AS CategoriaCreada,
            @AutorCreado     AS AutorCreado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
