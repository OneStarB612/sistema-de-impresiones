CREATE PROCEDURE [dbo].[pa_InsertPurchaseWithDetails]
    @UserID INT,
    @SupplierID INT,
    @DiscountAmount DECIMAL(18,4) = NULL,
    @DiscountPercentage DECIMAL(5,2) = NULL,
    @TaxPercentage DECIMAL(5,2) = NULL,
    @TaxAmount DECIMAL(18,4) = NULL,
    @CurrencyCode CHAR(3),
    @Observation VARCHAR(150) = NULL,
    @PurchaseDetailsJSON NVARCHAR(MAX),
    @PurchaseID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Variables para los cálculos
        DECLARE @Total DECIMAL(18,4);
        DECLARE @DetailCount INT;
        
        -- Validar parámetros requeridos
        IF @UserID IS NULL OR @SupplierID IS NULL OR @CurrencyCode IS NULL
        BEGIN
            RAISERROR('Los campos UserID, SupplierID y CurrencyCode son obligatorios', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Validar que el JSON no esté vacío
        IF @PurchaseDetailsJSON IS NULL OR LTRIM(RTRIM(@PurchaseDetailsJSON)) = ''
        BEGIN
            RAISERROR('El detalle de la compra no puede estar vacío', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Validar que el JSON sea válido
        IF ISJSON(@PurchaseDetailsJSON) = 0
        BEGIN
            RAISERROR('El formato del JSON no es válido', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Aplicar valores por defecto usando COALESCE
        SELECT 
            @DiscountAmount = COALESCE(@DiscountAmount, 0),
            @DiscountPercentage = COALESCE(@DiscountPercentage, 0),
            @TaxPercentage = COALESCE(@TaxPercentage, 0),
            @TaxAmount = COALESCE(@TaxAmount, 0);
        
        -- Verificar que existen los materiales en el detalle y calcular el total
        ;WITH DetailData AS (
            SELECT 
                MaterialID,
                Quantity,
                UnitPrice,
                COALESCE(DiscountAmount, 0) AS DiscountAmount,
                COALESCE(DiscountPercentage, 0) AS DiscountPercentage,
                COALESCE(TaxPercentage, 0) AS TaxPercentage,
                COALESCE(TaxAmount, 0) AS TaxAmount,
                COALESCE(SubTotal, 0) AS SubTotal
            FROM OPENJSON(@PurchaseDetailsJSON)
            WITH (
                MaterialID INT '$.MaterialID',
                Quantity INT '$.Quantity',
                UnitPrice DECIMAL(18,4) '$.UnitPrice',
                DiscountAmount DECIMAL(18,4) '$.DiscountAmount',
                DiscountPercentage DECIMAL(5,2) '$.DiscountPercentage',
                TaxPercentage DECIMAL(5,2) '$.TaxPercentage',
                TaxAmount DECIMAL(18,4) '$.TaxAmount',
                SubTotal DECIMAL(18,4) '$.SubTotal'
            )
        )
        SELECT 
            @Total = SUM(SubTotal),
            @DetailCount = COUNT(*)
        FROM DetailData d
        WHERE EXISTS (
            SELECT 1 FROM [dbo].[Material] m 
            WHERE m.MaterialID = d.MaterialID
        );
        
        -- Verificar que todos los materiales existen
        IF @DetailCount <> (SELECT COUNT(*) FROM OPENJSON(@PurchaseDetailsJSON))
        BEGIN
            RAISERROR('Uno o más materiales no existen en la base de datos', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Asegurar que no haya valores negativos
        IF @Total < 0 OR @DiscountAmount < 0 OR @TaxAmount < 0
        BEGIN
            RAISERROR('Los valores no pueden ser negativos', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Insertar el encabezado de la compra
        INSERT INTO [dbo].[Purchase] (
            [UserID],
            SupplierID,
            [DiscountAmount],
            [DiscountPercentage],
            [TaxPercentage],
            [TaxAmount],
            [CurrencyCode],
            [Total],
            [Observation]
        )
        VALUES (
            @UserID,
            @SupplierID,
            @DiscountAmount,
            @DiscountPercentage,
            @TaxPercentage,
            @TaxAmount,
            @CurrencyCode,
            @Total,
            @Observation
        );
        
        -- Obtener el ID de la compra insertada
        SET @PurchaseID = SCOPE_IDENTITY();
        
        -- Insertar los detalles de la compra usando parámetros con escape de inyección SQL
        INSERT INTO [dbo].[PurchaseDetail] (
            [PurchaseID],
            [MaterialID],
            [Quantity],
            [UnitPrice],
            [DiscountAmount],
            [DiscountPercentage],
            [TaxPercentage],
            [TaxAmount],
            [SubTotal]
        )
        SELECT 
            @PurchaseID,
            MaterialID,
            Quantity,
            UnitPrice,
            COALESCE(DiscountAmount, 0),
            COALESCE(DiscountPercentage, 0),
            COALESCE(TaxPercentage, 0),
            COALESCE(TaxAmount, 0),
            COALESCE(SubTotal, 0)
        FROM OPENJSON(@PurchaseDetailsJSON)
        WITH (
            MaterialID INT '$.MaterialID',
            Quantity INT '$.Quantity',
            UnitPrice DECIMAL(18,4) '$.UnitPrice',
            DiscountAmount DECIMAL(18,4) '$.DiscountAmount',
            DiscountPercentage DECIMAL(5,2) '$.DiscountPercentage',
            TaxPercentage DECIMAL(5,2) '$.TaxPercentage',
            TaxAmount DECIMAL(18,4) '$.TaxAmount',
            SubTotal DECIMAL(18,4) '$.SubTotal'
        );
        
        -- Verificar que se insertaron todos los detalles
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('No se pudo insertar el detalle de la compra', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        COMMIT TRANSACTION;
        
        -- Retornar el ID de la compra creada
        SELECT @PurchaseID AS PurchaseID;
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Ejemplo de uso del procedimiento
/*
DECLARE @PurchaseID BIGINT;
DECLARE @JSON NVARCHAR(MAX) = N'
[
    {
        "MaterialID": 1,
        "Quantity": 10,
        "UnitPrice": 100.50,
        "DiscountAmount": 10.00,
        "DiscountPercentage": 5.00,
        "TaxPercentage": 16.00,
        "TaxAmount": 16.08,
        "SubTotal": 1005.00
    },
    {
        "MaterialID": 2,
        "Quantity": 5,
        "UnitPrice": 200.00,
        "DiscountAmount": 0,
        "DiscountPercentage": 0,
        "TaxPercentage": 16.00,
        "TaxAmount": 32.00,
        "SubTotal": 1000.00
    }
]';

EXEC [dbo].[usp_InsertPurchaseWithDetails]
    @UserID = 1,
    @SupplierID = 1,
    @DiscountAmount = 15.00,
    @DiscountPercentage = 5.00,
    @TaxPercentage = 16.00,
    @TaxAmount = 48.08,
    @CurrencyCode = 'USD',
    @Observation = 'Compra de materiales',
    @PurchaseDetailsJSON = @JSON,
    @PurchaseID = @PurchaseID OUTPUT;

PRINT 'PurchaseID creado: ' + CAST(@PurchaseID AS VARCHAR);
*/