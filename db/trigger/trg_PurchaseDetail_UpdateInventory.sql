CREATE TRIGGER [dbo].[trg_PurchaseDetail_UpdateInventory]
ON [dbo].[PurchaseDetail]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla temporal para procesar las actualizaciones
        DECLARE @InventoryUpdates TABLE (
            MaterialID INT,
            TotalQuantity INT,
            CurrentClosedPackages INT,
            CurrentOpenPackages INT,
            CurrentRemainingPercentage DECIMAL(5,2),
            PackageCapacity DECIMAL(18,4),
            NewClosedPackages INT,
            NewOpenPackages INT,
            NewRemainingPercentage DECIMAL(5,2)
        );
        
        -- Obtener cantidades agrupadas por MaterialID
        ;WITH InsertedQuantities AS (
            SELECT 
                i.MaterialID,
                SUM(i.Quantity) AS TotalQuantity
            FROM inserted i
            GROUP BY i.MaterialID
        )
        -- Preparar datos para actualización
        INSERT INTO @InventoryUpdates (
            MaterialID,
            TotalQuantity,
            CurrentClosedPackages,
            CurrentOpenPackages,
            CurrentRemainingPercentage,
            PackageCapacity,
            NewClosedPackages,
            NewOpenPackages,
            NewRemainingPercentage
        )
        SELECT 
            iq.MaterialID,
            iq.TotalQuantity,
            ISNULL(mi.ClosedPackageCount, 0),
            ISNULL(mi.OpenPackageCount, 0),
            ISNULL(mi.RemainingPercentage, 100.00),
            ISNULL(mi.PackageCapacity, 1.0000),
            0, -- NewClosedPackages (se calculará)
            0, -- NewOpenPackages (se calculará)
            0.00 -- NewRemainingPercentage (se calculará)
        FROM InsertedQuantities iq
        INNER JOIN dbo.MaterialInventory mi ON iq.MaterialID = mi.MaterialID;
        
        -- Si algún material no tiene inventario, crearlo
        INSERT INTO dbo.MaterialInventory (
            MaterialID,
            PackageCapacity,
            ClosedPackageCount,
            OpenPackageCount,
            RemainingPercentage,
            UpdatedAt
        )
        SELECT 
            iq.MaterialID,
            1.0000, -- Capacidad por defecto
            0, -- ClosedPackageCount
            0, -- OpenPackageCount
            100.00, -- RemainingPercentage
            SYSUTCDATETIME()
        FROM (
            SELECT DISTINCT i.MaterialID
            FROM inserted i
            EXCEPT
            SELECT mi.MaterialID
            FROM dbo.MaterialInventory mi
        ) iq;
        
        -- Actualizar la tabla temporal con los nuevos valores
        UPDATE mu
        SET 
            -- La cantidad total se convierte en cajas cerradas (completas)
            NewClosedPackages = mu.CurrentClosedPackages + 
                FLOOR(mu.TotalQuantity / mu.PackageCapacity),
            -- Las cajas abiertas se mantienen como están (no se modifican con compras)
            NewOpenPackages = mu.CurrentOpenPackages,
            -- El porcentaje remanente se mantiene igual para las cajas abiertas existentes
            NewRemainingPercentage = mu.CurrentRemainingPercentage
        FROM @InventoryUpdates mu;
        
        -- Actualizar el inventario
        UPDATE mi
        SET 
            mi.ClosedPackageCount = mu.NewClosedPackages,
            mi.OpenPackageCount = mu.NewOpenPackages,
            mi.RemainingPercentage = mu.NewRemainingPercentage,
            mi.UpdatedAt = SYSUTCDATETIME()
        FROM dbo.MaterialInventory mi
        INNER JOIN @InventoryUpdates mu ON mi.MaterialID = mu.MaterialID
        WHERE mu.TotalQuantity > 0;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO