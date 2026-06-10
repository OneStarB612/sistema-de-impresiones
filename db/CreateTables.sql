

/*
CREATE TABLE [Supplier](
	SupplierID INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(30) NOT NULL,
	--direccion?
	CONSTRAINT [PK_Supplier] PRIMARY KEY (SupplierID)
);
GO
*/

CREATE TABLE [dbo].[Country] (
    [ISOAlpha2] CHAR(2) NOT NULL, -- e.g., 'US', 'FR', 'NI'
    [ISOAlpha3] CHAR(3) NOT NULL UNIQUE, -- e.g., 'USA', 'FRA', 'NIC'
    [ISONumeric] CHAR(3) NOT NULL UNIQUE, -- e.g., '840', '250', '558'
    [CommonName] VARCHAR(100) NOT NULL,
    [FormalName] VARCHAR(150),

	CONSTRAINT [PK_Country] PRIMARY KEY ([ISOAlpha2])
);

CREATE TABLE [dbo].[GeoDivision] (
    [GeoDivisionID] BIGINT IDENTITY(1,1) NOT NULL,
    [ParentID] BIGINT REFERENCES [GeoDivision]([GeoDivisionID]) ON DELETE NO ACTION,
    [ÇountryCode] CHAR(2) NOT NULL REFERENCES [Country]([ISOAlpha2]),
    [LevelType] VARCHAR(50) NOT NULL, -- 'state', 'province', 'department', 'municipality', 'district'
    [ISOSubDivisionCode] VARCHAR(10), -- e.g., 'US-CA' for California, 'NI-MN' for Managua
    [Name] VARCHAR(150) NOT NULL,
    
    CONSTRAINT [CK_LevelType] CHECK (LevelType IN ('region', 'state', 'province', 'department', 'county', 'municipality', 'city', 'district')),
	CONSTRAINT [PK_GeoDivisionID] PRIMARY KEY ([GeoDivisionID]),
);

CREATE TABLE [dbo].[User] (
    [UserID] INT IDENTITY(1,1) NOT NULL,
    [Name] VARCHAR(50) NOT NULL,
    [Lastname] VARCHAR(50) NOT NULL,
    [Active] BIT NOT NULL,

    CONSTRAINT [PK_User] PRIMARY KEY ([UserID]),
	CONSTRAINT [DF_User_Active] DEFAULT (1) FOR [Active]
);
GO

CREATE TABLE [dbo].[Supplier] (
    [SupplierID] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [ContactEmail] NVARCHAR(100) NULL,
    [Active] BIT NOT NULL,
    --[CreatedAt] DATETIME2(3) NOT NULL,
    
    CONSTRAINT [PK_Supplier] PRIMARY KEY ([SupplierID]),
    CONSTRAINT [UQ_Suppliers_Name] UNIQUE ([Name]),
	CONSTRAINT [DF_Suppliers_Active] DEFAULT (1) FOR [Active],
	--CONSTRAINT [DF_Suppliers_CreatedAt] DEFAULT SYSUTCDATETIME()
);

CREATE TABLE [dbo].[Category](
	[CategoryID] INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(25) NOT NULL,
	[Description] NVARCHAR(80) NULL,
	[Active] BIT NOT NULL,
	
	CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryID]),
	CONSTRAINT [DF_User_Active] DEFAULT (0) FOR [Active]
 );
 GO

 CREATE TABLE [dbo].[Material] (
    [MaterialID] INT IDENTITY(1,1) NOT NULL,
    [SKU] NVARCHAR(50) NOT NULL,
    [MaterialName] NVARCHAR(150) NOT NULL,
    --[UnitMeasure] NVARCHAR(20) NOT NULL, -- e.g., 'kg', 'L', 'g', one table
    [MinimumStockLevel] DECIMAL(18,4) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL,
    
    CONSTRAINT [PK_Material] PRIMARY KEY CLUSTERED ([MaterialID]),
    CONSTRAINT [UQ_Material_SKU] UNIQUE ([SKU]),
    CONSTRAINT [CK_Material_MinStock] CHECK ([MinimumStockLevel] >= (0)),
	CONSTRAINT [DF_Material_CreatedAt] DEFAULT SYSUTCDATETIME(),
	CONSTRAINT [DF_Material_MinStock] DEFAULT (0.0000)
);

CREATE TABLE dbo.MaterialInventory (
    InventoryID INT IDENTITY(1,1) NOT NULL,
    MaterialID INT NOT NULL,
    --StorageLocationCode NVARCHAR(50) NOT NULL, -- e.g., 'Aisle-04-Shelf-B'
    PackageCapacity DECIMAL(18,4) NOT NULL,   -- Amount a single brand-new box holds
    ClosedPackageCount INT NOT NULL CONSTRAINT DF_MaterialInventory_Closed DEFAULT (0),
    OpenPackageCount INT NOT NULL CONSTRAINT DF_MaterialInventory_Open DEFAULT (0),
    RemainingPercentage DECIMAL(5,2) NOT NULL CONSTRAINT DF_MaterialInventory_Percent DEFAULT (100.00),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_MaterialInventory_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    -- Architectural Requirement: Computed Column applying the explicit mathematical formula
    -- DRY Principle: Calculated at the database tier so client applications don't repeat logic.
    CurrentUsableStock AS CAST(
        (ClosedPackageCount * PackageCapacity) + 
        CASE 
            WHEN OpenPackageCount > 0 
            -- Calculates (OpenBoxesCount - 1) full capacities plus the fraction remaining in the active open box
            THEN ((OpenPackageCount - 1) * PackageCapacity) + ((RemainingPercentage / 100.00) * PackageCapacity)
            ELSE 0.0000
        END 
        AS DECIMAL(18,4)
    ),

    CONSTRAINT PK_MaterialInventory PRIMARY KEY (InventoryID),
    --CONSTRAINT UQ_MaterialInventory_MaterialLocation UNIQUE (MaterialID, StorageLocationCode),
    CONSTRAINT FK_MaterialInventory_Materials FOREIGN KEY (MaterialID) REFERENCES dbo.Material (MaterialID),
    CONSTRAINT CK_MaterialInventory_PackageCapacity CHECK (PackageCapacity > 0),
    CONSTRAINT CK_MaterialInventory_Closed CHECK (ClosedPackageCount >= 0),
    CONSTRAINT CK_MaterialInventory_Open CHECK (OpenPackageCount >= 0),
    CONSTRAINT CK_MaterialInventory_Percentage CHECK (RemainingPercentage BETWEEN 0.00 AND 100.00)
);

CREATE TABLE [dbo].[Product](
	[ProductID] INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(80) NOT NULL,
	[Description] NVARCHAR(80) NULL,
	[Active] BIT NOT NULL,
	[CategoryID] INT NULL,
	[UnitPrice] DECIMAL(12,2) NULL,
	[UnitCost] DECIMAL(12,2) NULL,
	[Stock] INT NULL,
	[Discontinued] BIT NOT NULL,
	
	CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID]),
	CONSTRAINT [DF_User_Active] DEFAULT (0) FOR [Active],
	CONSTRAINT [DF_Product_UnitPrice]  DEFAULT (0) FOR [UnitPrice],
	CONSTRAINT [DF_Product_UnitCost]  DEFAULT (0) FOR [UnitCost],
	CONSTRAINT [DF_Product_Stock]  DEFAULT (0) FOR [Stock],
	CONSTRAINT [DF_Product_Discontinued]  DEFAULT (0) FOR [Discontinued],
	CONSTRAINT [CK_Product_UnitPrice] CHECK  ([UnitPrice] >= 0),
	CONSTRAINT [CK_Product_UnitCost] CHECK  ([UnitCost] >= 0),
	CONSTRAINT [CK_Product_Stock] CHECK  ([Stock] >= 0),

	
	CONSTRAINT [FK_Product_Category] FOREIGN KEY([CategoryID]) REFERENCES [dbo].[Category] ([CategoryID])

);
GO

CREATE TABLE [dbo].[Sale](
	[SaleID] INT IDENTITY(1,1) NOT NULL,
	[CreatedAt] DATETIME2(3) NOT NULL,
	[UserID] INT NOT NULL,
	[Customer] VARCHAR(50) NOT NULL,
	[DiscountAmount] DECIMAL(18,4) NOT NULL,
	[DiscountPercentage] DECIMAL(5,2) NOT NULL,
	[TaxPercentage] DECIMAL(5,2) NOT NULL,
	[TaxAmount] DECIMAL(18, 4) NOT NULL,
	[CurrencyCode] NCHAR(3) NOT NULL,
	[Total] DECIMAL(18,4),
	[Observation] VARCHAR(150) NULL,

	CONSTRAINT [PK_Sale] PRIMARY KEY ([SaleID]),
	CONSTRAINT [DF_Sale_CreatedAt] DEFAULT sysutcdatetime() FOR [CreatedAt],
	CONSTRAINT [DF_Sale_DiscountPercentage] DEFAULT (0) FOR [DiscountPercentage],
	CONSTRAINT [CK_Sale_DiscountPercentage] CHECK ([DiscountPercentage] >= 0),
	CONSTRAINT [DF_Sale_DiscountAmount] DEFAULT (0) FOR [DiscountAmount],
	CONSTRAINT [CK_Sale_DiscountAmount] CHECK ([DiscountAmount] >= 0),
	CONSTRAINT [DF_Sale_TaxAmount] DEFAULT (0) FOR [TaxAmount],
	CONSTRAINT [CK_Sale_TaxAmount] CHECK ([TaxAmount] >= 0),
	CONSTRAINT [DF_Sale_Total] DEFAULT (0) FOR [Total],
	CONSTRAINT [CK_Sale_Total] CHECK ([Total] >= 0),

	CONSTRAINT [FK_User] FOREIGN KEY ([UserID]) REFERENCES [dbo].[User] ([UserID])
);
GO

CREATE TABLE [dbo].[SaleDetail] (
	[SaleDetailID] BIGINT IDENTITY(1,1),
	[SaleID] INT NOT NULL,
	[ProductID] INT NOT NULL,
	[Quantity] INT NOT NULL,
	[UnitPrice] DECIMAL(18,4) NOT NULL,
	[DiscountAmount] DECIMAL(18,4) NOT NULL,
	[DiscountPercentage] DECIMAL(5,2) NOT NULL,
	[TaxPercentage] DECIMAL(5,2) NOT NULL,
	[TaxAmount] DECIMAL(18,4) NOT NULL,
	[SubTotal] DECIMAL(18,4) NOT NULL,

	CONSTRAINT [PK_Sale] PRIMARY KEY ([SaleDetailID]),
	CONSTRAINT [DF_Sale_DiscountPercentage] DEFAULT (0) FOR [DiscountPercentage],
	CONSTRAINT [DF_Sale_DiscountAmount] DEFAULT (0) FOR [DiscountAmount],
	CONSTRAINT [DF_Sale_Quantity] DEFAULT (0) FOR [Quantity],
	CONSTRAINT [DF_Sale_TaxAmount] DEFAULT (0) FOR [TaxAmount],
	CONSTRAINT [DF_Sale_SubTotal] DEFAULT (0) FOR [SubTotal],
	CONSTRAINT [CK_Sale_DiscountPercentage] CHECK ([DiscountPercentage] >= 0),
	CONSTRAINT [CK_Sale_DiscountAmount] CHECK ([DiscountAmount] >= 0),
	CONSTRAINT [CK_Sale_Quantity] CHECK ([Quantity] >= 0),
	CONSTRAINT [CK_Sale_TaxAmount] CHECK ([TaxAmount] >= 0),
	CONSTRAINT [CK_Sale_SubTotal] CHECK ([SubTotal] >= 0),

	CONSTRAINT [FK_Sale] FOREIGN KEY ([SaleID]) REFERENCES [dbo].[Sale] ([SaleID])
);
GO