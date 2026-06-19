CREATE PROCEDURE sp_User_Update
    @UserID INT,
    @UserName NVARCHAR(150) = NULL,      -- NULL = no actualizar
    @Email NVARCHAR(256) = NULL,         -- NULL = no actualizar
    @PasswordHash NVARCHAR(512) = NULL,  -- NULL = no actualizar
    @Active BIT = NULL                   -- NULL = no actualizar
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para manejo de errores
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @CurrentUserName NVARCHAR(150);
    DECLARE @CurrentEmail NVARCHAR(256);
    
    BEGIN TRY
        -- ============================================
        -- VALIDACIONES DE PARÁMETROS
        -- ============================================
        
        -- Validar que el UserID no sea NULL
        IF @UserID IS NULL
        BEGIN
            RAISERROR('UserID es obligatorio', 16, 1);
            RETURN;
        END
        
        -- Validar que al menos un campo venga para actualizar
        IF @UserName IS NULL AND @Email IS NULL AND @PasswordHash IS NULL AND @Active IS NULL
        BEGIN
            RAISERROR('Debe especificar al menos un campo para actualizar', 16, 1);
            RETURN;
        END
        
        -- Validar longitudes si se proporcionan
        IF @UserName IS NOT NULL AND LEN(@UserName) > 150
        BEGIN
            RAISERROR('UserName excede la longitud máxima de 150 caracteres', 16, 1);
            RETURN;
        END
        
        IF @Email IS NOT NULL AND LEN(@Email) > 256
        BEGIN
            RAISERROR('Email excede la longitud máxima de 256 caracteres', 16, 1);
            RETURN;
        END
        
        IF @PasswordHash IS NOT NULL AND LEN(@PasswordHash) > 512
        BEGIN
            RAISERROR('PasswordHash excede la longitud máxima de 512 caracteres', 16, 1);
            RETURN;
        END
        
        -- Validar formato de email si se proporciona
        IF @Email IS NOT NULL AND @Email NOT LIKE '%_@_%._%'
        BEGIN
            RAISERROR('Formato de email inválido', 16, 1);
            RETURN;
        END
        
        -- ============================================
        -- VERIFICAR QUE EL USUARIO EXISTA
        -- ============================================
        
        IF NOT EXISTS (SELECT 1 FROM [dbo].[User] WHERE UserID = @UserID)
        BEGIN
            RAISERROR('El usuario especificado no existe', 16, 1);
            RETURN;
        END
        
        -- ============================================
        -- VALIDACIONES DE UNICIDAD (SI SE ACTUALIZAN)
        -- ============================================
        
        -- Si se va a actualizar el UserName, verificar que no esté en uso por otro usuario
        IF @UserName IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[User] WHERE UserName = @UserName AND UserID != @UserID)
            BEGIN
                RAISERROR('El nombre de usuario ya está en uso por otro usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Si se va a actualizar el Email, verificar que no esté en uso por otro usuario
        IF @Email IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[User] WHERE Email = @Email AND UserID != @UserID)
            BEGIN
                RAISERROR('El email ya está en uso por otro usuario', 16, 1);
                RETURN;
            END
        END
        
        -- ============================================
        -- OPERACIÓN DE ACTUALIZACIÓN
        -- ============================================
        
        -- Iniciar transacción
        BEGIN TRANSACTION;
        
        -- Obtener valores actuales para mantener si se pasan NULL
        SELECT 
            @CurrentUserName = UserName,
            @CurrentEmail = Email
        FROM [dbo].[User]
        WHERE UserID = @UserID;
        
        -- UPDATE con parámetros para prevenir inyección SQL
        UPDATE [dbo].[User]
        SET 
            UserName = COALESCE(@UserName, @CurrentUserName),    -- Mantener si NULL
            Email = COALESCE(@Email, @CurrentEmail),             -- Mantener si NULL
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),-- Mantener si NULL
            Active = COALESCE(@Active, Active)                   -- Mantener si NULL
            -- CreatedAt NO se actualiza (debe mantener fecha de creación original)
            -- Si necesitas un campo de última actualización, agregar UpdateAt
        WHERE 
            UserID = @UserID;
        
        -- Confirmar transacción
        COMMIT TRANSACTION;
        
        -- Retornar el ID del usuario actualizado
        SELECT @UserID AS UserID, 'Usuario actualizado exitosamente' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        -- Revertir transacción en caso de error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Obtener información del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Lanzar el error con información detallada
        RAISERROR(
            'Error en sp_User_Update: %s. Código de error: %d',
            @ErrorSeverity,
            @ErrorState,
            @ErrorMessage,
            ERROR_NUMBER()
        );
        
        -- Retornar -1 para indicar error
        SELECT -1 AS UserID, 'Error al actualizar usuario' AS Mensaje;
    END CATCH
END
GO