CREATE TRIGGER [dbo].[trg_SaleDetail_UpdateStock]
ON [dbo].[SaleDetail]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para control de errores
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    -- Variables para actualización de stock
    DECLARE @ProductID INT;
    DECLARE @QuantityChange INT;
    DECLARE @CurrentStock INT;
    DECLARE @NewStock INT;
    
    BEGIN TRY
        -- 1. Manejar operación de INSERCIÓN (nuevas ventas)
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- Actualizar stock restando las cantidades vendidas
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) - i.Quantity
            FROM [dbo].[Product] p
            INNER JOIN inserted i ON p.ProductID = i.ProductID
            WHERE i.Quantity > 0;
            
            -- Verificar que ningún stock quede negativo
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[Product] 
                WHERE Stock < 0
            )
            BEGIN
                -- Revertir cambios si hay stock negativo
                UPDATE p
                SET p.Stock = ISNULL(p.Stock, 0) + i.Quantity
                FROM [dbo].[Product] p
                INNER JOIN inserted i ON p.ProductID = i.ProductID
                WHERE i.Quantity > 0;
                
                THROW 50000, 'No se puede realizar la venta: Stock insuficiente para uno o más productos', 1;
            END
        END
        
        -- 2. Manejar operación de ACTUALIZACIÓN (cambios en cantidad)
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- Crear tabla temporal para calcular diferencias
            DECLARE @StockChanges TABLE (
                ProductID INT,
                QuantityChange INT
            );
            
            -- Calcular la diferencia neta por producto (cantidad nueva - cantidad antigua)
            INSERT INTO @StockChanges (ProductID, QuantityChange)
            SELECT 
                i.ProductID,
                ISNULL(i.Quantity, 0) - ISNULL(d.Quantity, 0)
            FROM inserted i
            INNER JOIN deleted d ON i.SaleDetailID = d.SaleDetailID
            WHERE ISNULL(i.Quantity, 0) != ISNULL(d.Quantity, 0);
            
            -- Actualizar stock según las diferencias
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) - sc.QuantityChange
            FROM [dbo].[Product] p
            INNER JOIN @StockChanges sc ON p.ProductID = sc.ProductID;
            
            -- Verificar que ningún stock quede negativo
            IF EXISTS (
                SELECT 1 
                FROM [dbo].[Product] 
                WHERE Stock < 0
            )
            BEGIN
                -- Revertir cambios
                UPDATE p
                SET p.Stock = ISNULL(p.Stock, 0) + sc.QuantityChange
                FROM [dbo].[Product] p
                INNER JOIN @StockChanges sc ON p.ProductID = sc.ProductID;
                
                THROW 50000, 'No se puede actualizar la venta: Stock insuficiente para uno o más productos', 1;
            END
        END
        
        -- 3. Manejar operación de ELIMINACIÓN (anulación de venta)
        IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- Devolver el stock sumando las cantidades que se estaban eliminando
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) + d.Quantity
            FROM [dbo].[Product] p
            INNER JOIN deleted d ON p.ProductID = d.ProductID
            WHERE d.Quantity > 0;
        END
        
        -- 4. Log de auditoría (opcional)
        -- Registrar cambios en una tabla de auditoría
        -- INSERT INTO Audit_StockLog (ProductID, OldStock, NewStock, ChangeDate, ChangeType)
        -- SELECT ...
        
    END TRY
    BEGIN CATCH
        -- Manejar errores y hacer rollback de la transacción
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Trigger alternativo más robusto con validaciones previas
CREATE TRIGGER [dbo].[trg_SaleDetail_UpdateStock_Advanced]
ON [dbo].[SaleDetail]
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ProductID INT;
    DECLARE @RequiredQty INT;
    DECLARE @AvailableStock INT;
    
    BEGIN TRY
        -- Validar stock antes de la operación (para INSERT y UPDATE)
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            -- Verificar stock disponible para cada producto en la operación
            DECLARE stock_cursor CURSOR FOR
            SELECT DISTINCT
                i.ProductID,
                ISNULL(i.Quantity, 0) - ISNULL(d.Quantity, 0) AS RequiredQty
            FROM inserted i
            LEFT JOIN deleted d ON i.SaleDetailID = d.SaleDetailID
            WHERE ISNULL(i.Quantity, 0) - ISNULL(d.Quantity, 0) > 0;
            
            OPEN stock_cursor;
            
            FETCH NEXT FROM stock_cursor INTO @ProductID, @RequiredQty;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Obtener stock actual
                SELECT @AvailableStock = ISNULL(Stock, 0)
                FROM [dbo].[Product]
                WHERE ProductID = @ProductID;
                
                -- Verificar si hay suficiente stock
                IF @AvailableStock < @RequiredQty
                BEGIN
                    CLOSE stock_cursor;
                    DEALLOCATE stock_cursor;
                    
                    THROW 50000, 
                        CONCAT('Stock insuficiente para el producto ', @ProductID, 
                               '. Disponible: ', @AvailableStock, 
                               ', Requerido: ', @RequiredQty), 1;
                END
                
                FETCH NEXT FROM stock_cursor INTO @ProductID, @RequiredQty;
            END
            
            CLOSE stock_cursor;
            DEALLOCATE stock_cursor;
        END
        
        -- Realizar la operación original
        IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        BEGIN
            -- DELETE: Realizar el DELETE y actualizar stock
            DELETE FROM [dbo].[SaleDetail]
            WHERE SaleDetailID IN (SELECT SaleDetailID FROM deleted);
            
            -- Actualizar stock (devolver)
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) + d.Quantity
            FROM [dbo].[Product] p
            INNER JOIN deleted d ON p.ProductID = d.ProductID;
        END
        ELSE IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- INSERT: Actualizar stock primero, luego insertar
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) - i.Quantity
            FROM [dbo].[Product] p
            INNER JOIN inserted i ON p.ProductID = i.ProductID;
            
            -- Insertar los nuevos registros
            INSERT INTO [dbo].[SaleDetail] (
                SaleID, ProductID, Quantity, UnitPrice, 
                DiscountAmount, DiscountPercentage, TaxPercentage,
                TaxAmount, SubTotal
            )
            SELECT 
                SaleID, ProductID, Quantity, UnitPrice,
                DiscountAmount, DiscountPercentage, TaxPercentage,
                TaxAmount, SubTotal
            FROM inserted;
        END
        ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- UPDATE: Primero devolver stock del registro antiguo
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) + d.Quantity
            FROM [dbo].[Product] p
            INNER JOIN deleted d ON p.ProductID = d.ProductID;
            
            -- Luego restar stock del registro nuevo
            UPDATE p
            SET p.Stock = ISNULL(p.Stock, 0) - i.Quantity
            FROM [dbo].[Product] p
            INNER JOIN inserted i ON p.ProductID = i.ProductID;
            
            -- Actualizar los registros
            UPDATE sd
            SET 
                sd.ProductID = i.ProductID,
                sd.Quantity = i.Quantity,
                sd.UnitPrice = i.UnitPrice,
                sd.DiscountAmount = i.DiscountAmount,
                sd.DiscountPercentage = i.DiscountPercentage,
                sd.TaxPercentage = i.TaxPercentage,
                sd.TaxAmount = i.TaxAmount,
                sd.SubTotal = i.SubTotal
            FROM [dbo].[SaleDetail] sd
            INNER JOIN inserted i ON sd.SaleDetailID = i.SaleDetailID;
        END
        
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

-- Trigger de auditoría para registrar cambios de stock
CREATE TRIGGER [dbo].[trg_Product_AuditStock]
ON [dbo].[Product]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Solo registrar cuando cambia el stock
    IF UPDATE(Stock)
    BEGIN
        -- Crear tabla temporal para auditoría si no existe
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Audit_StockChanges')
        BEGIN
            CREATE TABLE [dbo].[Audit_StockChanges] (
                AuditID INT IDENTITY(1,1),
                ProductID INT,
                OldStock INT,
                NewStock INT,
                ChangeDate DATETIME2(3) DEFAULT SYSDATETIME(),
                ChangedBy NVARCHAR(128) DEFAULT SYSTEM_USER,
                OperationType NVARCHAR(50)
            );
        END
        
        -- Registrar cambios
        INSERT INTO [dbo].[Audit_StockChanges] (
            ProductID,
            OldStock,
            NewStock,
            OperationType
        )
        SELECT 
            i.ProductID,
            ISNULL(d.Stock, 0) AS OldStock,
            ISNULL(i.Stock, 0) AS NewStock,
            'UPDATE_STOCK'
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE ISNULL(i.Stock, 0) != ISNULL(d.Stock, 0);
    END
END
GO

-- Función auxiliar para verificar disponibilidad de stock
CREATE FUNCTION [dbo].[fn_CheckStockAvailability](
    @ProductID INT,
    @RequiredQuantity INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @AvailableStock INT;
    DECLARE @IsAvailable BIT = 0;
    
    SELECT @AvailableStock = ISNULL(Stock, 0)
    FROM [dbo].[Product]
    WHERE ProductID = @ProductID;
    
    IF @AvailableStock >= @RequiredQuantity
        SET @IsAvailable = 1;
        
    RETURN @IsAvailable;
END
GO

-- Procedimiento para verificar y reservar stock
CREATE PROCEDURE [dbo].[usp_ReserveStock]
    @ProductID INT,
    @Quantity INT,
    @ReservationID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar disponibilidad
        IF dbo.fn_CheckStockAvailability(@ProductID, @Quantity) = 0
            THROW 50000, 'Stock insuficiente para reservar', 1;
        
        -- Actualizar stock (reservar)
        UPDATE [dbo].[Product]
        SET Stock = Stock - @Quantity
        WHERE ProductID = @ProductID
            AND Stock >= @Quantity;
        
        -- Verificar que se actualizó correctamente
        IF @@ROWCOUNT = 0
            THROW 50000, 'No se pudo reservar el stock', 1;
            
        -- Generar ID de reserva (simplificado)
        SET @ReservationID = CAST(CAST(GETDATE() AS FLOAT) * 1000000 AS INT) + @ProductID;
        
        -- Registrar la reserva (opcional)
        -- INSERT INTO StockReservations (ReservationID, ProductID, Quantity, ReservationDate)
        -- VALUES (@ReservationID, @ProductID, @Quantity, GETDATE());
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @ReservationID = -1;
        THROW;
    END CATCH
END
GO