USE BibliotecaDB;
GO

CREATE OR ALTER TRIGGER dbo.trg_Prestamo_Devolucion
ON dbo.Prestamo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(FechaDevolucion)
        RETURN;

    -- Actualiza el ejemplar cuando un préstamo pasa a Devuelto.
    UPDATE e
    SET e.Estado = 'Disponible'
    FROM dbo.Ejemplar e
    INNER JOIN inserted i ON i.EjemplarID = e.EjemplarID
    INNER JOIN deleted d ON d.PrestamoID = i.PrestamoID
    WHERE i.Estado = 'Devuelto'
      AND d.Estado <> 'Devuelto';

    -- Genera multa automáticamente si la devolución fue tardía.
    INSERT INTO dbo.Multa (PrestamoID, DiasRetraso, Valor)
    SELECT
        i.PrestamoID,
        DATEDIFF(DAY, i.FechaVencimiento, i.FechaDevolucion),
        dbo.fn_CalcularMulta(DATEDIFF(DAY, i.FechaVencimiento, i.FechaDevolucion))
    FROM inserted i
    INNER JOIN deleted d ON d.PrestamoID = i.PrestamoID
    WHERE i.Estado = 'Devuelto'
      AND d.Estado <> 'Devuelto'
      AND i.FechaDevolucion > i.FechaVencimiento
      AND NOT EXISTS (
          SELECT 1 FROM dbo.Multa m WHERE m.PrestamoID = i.PrestamoID
      );
END;
GO
