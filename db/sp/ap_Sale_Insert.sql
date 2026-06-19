CREATE PROCEDURE [dbo].[pa_UpsertSale]
    -- Parámetros para Sale
    @SaleID BIGINT = NULL,
    @UserID INT,
    @CustomerID BIGINT,
    @CustomerName NVARCHAR(100) = NULL,
    @DiscountAmount DECIMAL(18,4) = 0,
    @DiscountPercentage DECIMAL(5,2) = 0,
    @TaxPercentage DECIMAL(5,2) = 0,
    @CurrencyCode CHAR(3),
    @Observation VARCHAR(150) = NULL,
    
    -- Parámetros para SaleDetail (como tabla con valores)
    @SaleDetails NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables de control
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @CurrentSaleID BIGINT;
    
    -- Variables para cálculos
    DECLARE @TaxAmount DECIMAL(18,4);
    DECLARE @Total DECIMAL(18,4);
    
    -- Valores por defecto para campos NULL
    SET @DiscountAmount = ISNULL(@DiscountAmount, 0);
    SET @DiscountPercentage = ISNULL(@DiscountPercentage, 0);
    SET @TaxPercentage = ISNULL(@TaxPercentage, 0);
    SET @Observation = ISNULL(@Observation, '');
    SET @CustomerName = ISNULL(@CustomerName, '');
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validaciones de negocio
        IF @UserID IS NULL
            THROW 50000, 'El UserID es obligatorio', 1;
            
        IF @CustomerID IS NULL
            THROW 50000, 'El CustomerID es obligatorio', 1;
            
        IF @CurrencyCode IS NULL OR LEN(@CurrencyCode) != 3
            THROW 50000, 'El CurrencyCode debe ser de 3 caracteres', 1;
            
        IF @DiscountAmount < 0 OR @DiscountPercentage < 0 OR @TaxPercentage < 0
            THROW 50000, 'Los valores de descuento e impuestos no pueden ser negativos', 1;
        
        -- Si es UPDATE (SaleID existe)
        IF @SaleID IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Sale] WHERE SaleID = @SaleID)
        BEGIN
            -- Actualizar Sale
            UPDATE [dbo].[Sale]
            SET 
                UserID = @UserID,
                CustomerID = @CustomerID,
                CustomerName = @CustomerName,
                DiscountAmount = @DiscountAmount,
                DiscountPercentage = @DiscountPercentage,
                TaxPercentage = @TaxPercentage,
                CurrencyCode = @CurrencyCode,
                Observation = @Observation
            WHERE SaleID = @SaleID;
            
            SET @CurrentSaleID = @SaleID;
            
            -- Si se proporcionan detalles, eliminar los antiguos
            IF @SaleDetails IS NOT NULL AND @SaleDetails != ''
            BEGIN
                -- Eliminar detalles antiguos
                DELETE FROM [dbo].[SaleDetail] WHERE SaleID = @CurrentSaleID;
                
                -- Insertar nuevos detalles
                EXEC [dbo].[usp_InsertSaleDetails] 
                    @SaleID = @CurrentSaleID,
                    @SaleDetails = @SaleDetails;
            END
        END
        ELSE
        BEGIN
            -- Si es INSERT (SaleID NULL)
            -- Calcular impuestos y total
            SET @TaxAmount = 0; -- Se recalculará basado en detalles
            SET @Total = 0; -- Se recalculará basado en detalles
            
            -- Insertar Sale
            INSERT INTO [dbo].[Sale] (
                UserID,
                CustomerID,
                CustomerName,
                DiscountAmount,
                DiscountPercentage,
                TaxPercentage,
                TaxAmount,
                CurrencyCode,
                Total,
                Observation
            )
            VALUES (
                @UserID,
                @CustomerID,
                @CustomerName,
                @DiscountAmount,
                @DiscountPercentage,
                @TaxPercentage,
                @TaxAmount,  -- Temporal, se actualizará después
                @CurrencyCode,
                @Total,      -- Temporal, se actualizará después
                @Observation
            );
            
            SET @CurrentSaleID = SCOPE_IDENTITY();
            
            -- Si se proporcionan detalles, insertarlos
            IF @SaleDetails IS NOT NULL AND @SaleDetails != ''
            BEGIN
                EXEC [dbo].[usp_InsertSaleDetails] 
                    @SaleID = @CurrentSaleID,
                    @SaleDetails = @SaleDetails;
                
                -- Recalcular totales de la venta basado en los detalles
                SELECT 
                    @Total = ISNULL(SUM(SubTotal), 0),
                    @TaxAmount = ISNULL(SUM(TaxAmount), 0)
                FROM [dbo].[SaleDetail]
                WHERE SaleID = @CurrentSaleID;
                
                -- Aplicar descuentos a nivel de venta
                SET @Total = @Total - @DiscountAmount;
                SET @Total = @Total * (1 - @DiscountPercentage / 100);
                SET @TaxAmount = @TaxAmount + (@Total * @TaxPercentage / 100);
                SET @Total = @Total + @TaxAmount;
                
                -- Actualizar totales de la venta
                UPDATE [dbo].[Sale]
                SET 
                    TaxAmount = @TaxAmount,
                    Total = @Total
                WHERE SaleID = @CurrentSaleID;
            END
        END
        
        -- Obtener la venta completa para retornar
        SELECT 
            s.SaleID,
            s.CreatedAt,
            s.UserID,
            s.CustomerID,
            s.CustomerName,
            s.DiscountAmount,
            s.DiscountPercentage,
            s.TaxPercentage,
            s.TaxAmount,
            s.CurrencyCode,
            s.Total,
            s.Observation,
            sd.SaleDetailID,
            sd.ProductID,
            sd.Quantity,
            sd.UnitPrice,
            sd.DiscountAmount AS DetailDiscountAmount,
            sd.DiscountPercentage AS DetailDiscountPercentage,
            sd.TaxPercentage AS DetailTaxPercentage,
            sd.TaxAmount AS DetailTaxAmount,
            sd.SubTotal
        FROM [dbo].[Sale] s
        LEFT JOIN [dbo].[SaleDetail] sd ON s.SaleID = sd.SaleID
        WHERE s.SaleID = @CurrentSaleID
        ORDER BY sd.SaleDetailID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Procedimiento auxiliar para insertar detalles
CREATE PROCEDURE [dbo].[usp_InsertSaleDetails]
    @SaleID BIGINT,
    @SaleDetails NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que el JSON no esté vacío
    IF @SaleDetails IS NULL OR @SaleDetails = ''
        RETURN;
    
    -- Validar que los datos sean JSON válido
    IF ISJSON(@SaleDetails) = 0
        THROW 50000, 'Los datos de SaleDetails no son un JSON válido', 1;
    
    -- Insertar detalles desde JSON
    INSERT INTO [dbo].[SaleDetail] (
        SaleID,
        ProductID,
        Quantity,
        UnitPrice,
        DiscountAmount,
        DiscountPercentage,
        TaxPercentage,
        TaxAmount,
        SubTotal
    )
    SELECT 
        @SaleID,
        ISNULL(JSON_VALUE(value, '$.ProductID'), 0),
        ISNULL(JSON_VALUE(value, '$.Quantity'), 1),
        ISNULL(JSON_VALUE(value, '$.UnitPrice'), 0),
        ISNULL(JSON_VALUE(value, '$.DiscountAmount'), 0),
        ISNULL(JSON_VALUE(value, '$.DiscountPercentage'), 0),
        ISNULL(JSON_VALUE(value, '$.TaxPercentage'), 0),
        -- Calcular TaxAmount y SubTotal automáticamente
        ISNULL(JSON_VALUE(value, '$.Quantity'), 1) * 
        ISNULL(JSON_VALUE(value, '$.UnitPrice'), 0) * 
        ISNULL(JSON_VALUE(value, '$.TaxPercentage'), 0) / 100,
        ISNULL(JSON_VALUE(value, '$.Quantity'), 1) * 
        ISNULL(JSON_VALUE(value, '$.UnitPrice'), 0) * 
        (1 - ISNULL(JSON_VALUE(value, '$.DiscountPercentage'), 0) / 100)
    FROM OPENJSON(@SaleDetails);
    
    -- Verificar que se insertaron detalles
    IF @@ROWCOUNT = 0
        THROW 50000, 'No se pudo insertar ningún detalle de venta', 1;
END
GO

-- Procedimiento para obtener una venta
CREATE PROCEDURE [dbo].[pa_GetSale]
    @SaleID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar parámetros
    IF @SaleID IS NULL
        THROW 50000, 'El SaleID es obligatorio', 1;
    
    -- Obtener la venta con sus detalles
    SELECT 
        s.SaleID,
        s.CreatedAt,
        s.UserID,
        s.CustomerID,
        s.CustomerName,
        s.DiscountAmount,
        s.DiscountPercentage,
        s.TaxPercentage,
        s.TaxAmount,
        s.CurrencyCode,
        s.Total,
        s.Observation,
        sd.SaleDetailID,
        sd.ProductID,
        sd.Quantity,
        sd.UnitPrice,
        sd.DiscountAmount AS DetailDiscountAmount,
        sd.DiscountPercentage AS DetailDiscountPercentage,
        sd.TaxPercentage AS DetailTaxPercentage,
        sd.TaxAmount AS DetailTaxAmount,
        sd.SubTotal
    FROM [dbo].[Sale] s
    LEFT JOIN [dbo].[SaleDetail] sd ON s.SaleID = sd.SaleID
    WHERE s.SaleID = @SaleID
    ORDER BY sd.SaleDetailID;
END
GO

-- Procedimiento para eliminar una venta
CREATE PROCEDURE [dbo].[pa_DeleteSale]
    @SaleID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar parámetros
        IF @SaleID IS NULL
            THROW 50000, 'El SaleID es obligatorio', 1;
        
        -- Verificar que la venta existe
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sale] WHERE SaleID = @SaleID)
            THROW 50000, 'La venta no existe', 1;
        
        -- Eliminar detalles de la venta
        DELETE FROM [dbo].[SaleDetail] WHERE SaleID = @SaleID;
        
        -- Eliminar la venta
        DELETE FROM [dbo].[Sale] WHERE SaleID = @SaleID;
        
        -- Retornar mensaje de éxito
        SELECT 'Venta eliminada exitosamente' AS Message;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END
GO