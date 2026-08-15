USE BibliotecaDB;
GO

CREATE OR ALTER FUNCTION dbo.fn_CalcularMulta
(
    @DiasRetraso INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Valor DECIMAL(10,2);

    SET @Valor =
        CASE
            WHEN @DiasRetraso <= 0 THEN 0
            WHEN @DiasRetraso <= 5 THEN @DiasRetraso * 2000.00
            WHEN @DiasRetraso <= 15 THEN 10000.00 + ((@DiasRetraso - 5) * 3000.00)
            ELSE 40000.00 + ((@DiasRetraso - 15) * 5000.00)
        END;

    RETURN @Valor;
END;
GO
