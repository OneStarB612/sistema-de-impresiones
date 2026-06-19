CREATE PROCEDURE pa_User_Create
    @UserName NVARCHAR(150),
    @Email NVARCHAR(256),
    @PasswordHash NVARCHAR(512),
    @Active BIT = NULL  -- Si no se especifica, usa el valor por defecto (1)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para manejo de errores
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @UserID INT;
    
    BEGIN TRY
        -- ============================================
        -- VALIDACIONES DE PARÁMETROS OBLIGATORIOS
        -- ============================================
        
        -- Validar que los parámetros obligatorios no sean NULL
        IF @UserName IS NULL OR @Email IS NULL OR @PasswordHash IS NULL
        BEGIN
            RAISERROR('UserName, Email y PasswordHash son obligatorios', 16, 1);
            RETURN;
        END
        
        -- Validar longitud de campos
        IF LEN(@UserName) > 150
        BEGIN
            RAISERROR('UserName excede la longitud máxima de 150 caracteres', 16, 1);
            RETURN;
        END
        
        IF LEN(@Email) > 256
        BEGIN
            RAISERROR('Email excede la longitud máxima de 256 caracteres', 16, 1);
            RETURN;
        END
        
        IF LEN(@PasswordHash) > 512
        BEGIN
            RAISERROR('PasswordHash excede la longitud máxima de 512 caracteres', 16, 1);
            RETURN;
        END
        
        -- Validar formato de email (básico)
        IF @Email NOT LIKE '%_@_%._%'
        BEGIN
            RAISERROR('Formato de email inválido', 16, 1);
            RETURN;
        END
        
        -- ============================================
        -- VALIDACIONES DE UNICIDAD (PREVENIR DUPLICADOS)
        -- ============================================
        
        -- Verificar que el UserName no exista
        IF EXISTS (SELECT 1 FROM [dbo].[User] WHERE UserName = @UserName)
        BEGIN
            RAISERROR('El nombre de usuario ya existe', 16, 1);
            RETURN;
        END
        
        -- Verificar que el Email no exista
        IF EXISTS (SELECT 1 FROM [dbo].[User] WHERE Email = @Email)
        BEGIN
            RAISERROR('El email ya está registrado', 16, 1);
            RETURN;
        END
        
        -- ============================================
        -- OPERACIÓN DE INSERCIÓN
        -- ============================================
        
        -- Iniciar transacción
        BEGIN TRANSACTION;
        
        -- INSERT con parámetros para prevenir inyección SQL
        INSERT INTO [dbo].[User] (
            UserName,
            Email,
            PasswordHash,
            Active,
            CreatedAt
        )
        VALUES (
            @UserName,                -- Parametrizado automáticamente
            @Email,                   -- Parametrizado automáticamente
            @PasswordHash,            -- Parametrizado automáticamente
            COALESCE(@Active, 1),     -- Si es NULL, usa 1 (activo por defecto)
            SYSUTCDATETIME()          -- Siempre UTC
        );
        
        -- Obtener el ID generado
        SET @UserID = SCOPE_IDENTITY();
        
        -- Confirmar transacción
        COMMIT TRANSACTION;
        
        -- Retornar el ID del usuario creado
        SELECT @UserID AS UserID, 'Usuario creado exitosamente' AS Mensaje;
        
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
            'Error en sp_User_Create: %s. Código de error: %d',
            @ErrorSeverity,
            @ErrorState,
            @ErrorMessage,
            ERROR_NUMBER()
        );
        
        -- Retornar -1 para indicar error
        SELECT -1 AS UserID, 'Error al crear usuario' AS Mensaje;
    END CATCH
END
GO