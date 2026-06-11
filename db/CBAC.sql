-- Ensure atomic execution
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO



CREATE TABLE dbo.Users (
    UserId INT IDENTITY(1,1) NOT NULL,
    Username NVARCHAR(150) NOT NULL,
    Email NVARCHAR(256) NOT NULL,
    PasswordHash NVARCHAR(MAX) NOT NULL, -- Store salted hashes only
    IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);

CREATE TABLE dbo.Roles (
    RoleId INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(256) NULL,
    CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (RoleId),
    CONSTRAINT UQ_Roles_Name UNIQUE (Name)
);

-- Junction table for User-Role relationship (Many-to-Many)
CREATE TABLE dbo.UserRoles (
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    CONSTRAINT PK_UserRoles PRIMARY KEY CLUSTERED (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_UserRoles_RoleId ON dbo.UserRoles(RoleId);



CREATE TABLE dbo.Claims (
    ClaimId INT IDENTITY(1,1) NOT NULL,
    ClaimType NVARCHAR(250) NOT NULL,  -- e.g., 'urn:permission' or 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role'
    ClaimValue NVARCHAR(250) NOT NULL, -- e.g., 'Create', 'Update'
    CONSTRAINT PK_Claims PRIMARY KEY CLUSTERED (ClaimId),
    CONSTRAINT UQ_Claims_Type_Value UNIQUE (ClaimType, ClaimValue)
);

-- Role-Based Claims (Inherited Authorization)
CREATE TABLE dbo.RoleClaims (
    RoleClaimId INT IDENTITY(1,1) NOT NULL,
    RoleId INT NOT NULL,
    ClaimId INT NOT NULL,
    CONSTRAINT PK_RoleClaims PRIMARY KEY CLUSTERED (RoleClaimId),
    CONSTRAINT FK_RoleClaims_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId) ON DELETE CASCADE,
    CONSTRAINT FK_RoleClaims_Claims FOREIGN KEY (ClaimId) REFERENCES dbo.Claims (ClaimId) ON DELETE CASCADE,
    CONSTRAINT UQ_RoleClaims_Role_Claim UNIQUE (RoleId, ClaimId)
);
CREATE NONCLUSTERED INDEX IX_RoleClaims_ClaimId ON dbo.RoleClaims(ClaimId);

-- Direct User Claims (Explicit Overrides / Strict CBAC)
CREATE TABLE dbo.UserClaims (
    UserClaimId INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    ClaimId INT NOT NULL,
    CONSTRAINT PK_UserClaims PRIMARY KEY CLUSTERED (UserClaimId),
    CONSTRAINT FK_UserClaims_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserClaims_Claims FOREIGN KEY (ClaimId) REFERENCES dbo.Claims (ClaimId) ON DELETE CASCADE,
    CONSTRAINT UQ_UserClaims_User_Claim UNIQUE (UserId, ClaimId)
);
CREATE NONCLUSTERED INDEX IX_UserClaims_ClaimId ON dbo.UserClaims(ClaimId);
GO

-- 1. Insert Roles
INSERT INTO dbo.Roles (Name, Description) VALUES 
('Admin', 'System Administrator with full horizontal privileges.'),
('Employee', 'Standard staff member with operational access.');

-- 2. Insert Claims (Using uniform URN formatting for Type definitions)
INSERT INTO dbo.Claims (ClaimType, ClaimValue) VALUES 
('urn:action:permission', 'create'),
('urn:action:permission', 'consult'),
('urn:action:permission', 'update'),
('urn:action:permission', 'delete');

-- 3. Map Claims to Roles
-- Admin mapping: Can create, consult, delete, update (All 4 claims)
INSERT INTO dbo.RoleClaims (RoleId, ClaimId)
SELECT r.RoleId, c.ClaimId
FROM dbo.Roles r
CROSS JOIN dbo.Claims c
WHERE r.Name = 'Admin';

-- Employee mapping: Can consult, create, update
INSERT INTO dbo.RoleClaims (RoleId, ClaimId)
SELECT r.RoleId, c.ClaimId
FROM dbo.Roles r
CROSS JOIN dbo.Claims c
WHERE r.Name = 'Employee' 
  AND c.ClaimValue IN ('create', 'consult', 'update');
GO