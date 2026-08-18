USE BibliotecaDB;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPrestamo
    @UsuarioID INT,
    @EjemplarID INT,
    @DiasPrestamo INT = 14
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @DiasPrestamo NOT BETWEEN 1 AND 60
            THROW 50001, 'Los días de préstamo deben estar entre 1 y 60.', 1;

        DECLARE @MaxPrestamos INT, @Activos INT, @EstadoEjemplar NVARCHAR(20);

        SELECT
            @MaxPrestamos = MaxPrestamos
        FROM dbo.Usuario
        WHERE UsuarioID = @UsuarioID
          AND Activo = 1;

        IF @MaxPrestamos IS NULL
            THROW 50002, 'El usuario no existe o está inactivo.', 1;

        SELECT @Activos = COUNT(*)
        FROM dbo.Prestamo
        WHERE UsuarioID = @UsuarioID
          AND Estado = 'Activo';

        IF @Activos >= @MaxPrestamos
            THROW 50003, 'El usuario alcanzó el límite de préstamos activos.', 1;

        SELECT @EstadoEjemplar = Estado
        FROM dbo.Ejemplar WITH (UPDLOCK, HOLDLOCK)
        WHERE EjemplarID = @EjemplarID;

        IF @EstadoEjemplar IS NULL
            THROW 50004, 'El ejemplar no existe.', 1;

        IF @EstadoEjemplar <> 'Disponible'
            THROW 50005, 'El ejemplar no está disponible para préstamo.', 1;

        DECLARE @PrestamoID INT;

        INSERT INTO dbo.Prestamo
            (UsuarioID, EjemplarID, FechaPrestamo, FechaVencimiento, Estado)
        OUTPUT INSERTED.PrestamoID, INSERTED.FechaPrestamo, INSERTED.FechaVencimiento
        VALUES
            (@UsuarioID, @EjemplarID, CAST(GETDATE() AS DATE),
             DATEADD(DAY, @DiasPrestamo, CAST(GETDATE() AS DATE)), 'Activo');

        SET @PrestamoID = SCOPE_IDENTITY();

        UPDATE dbo.Ejemplar
        SET Estado = 'Prestado'
        WHERE EjemplarID = @EjemplarID;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
