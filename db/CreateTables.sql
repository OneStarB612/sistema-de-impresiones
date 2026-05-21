

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
    [GeoDivisionID] INT IDENTITY(1,1) NOT NULL,
    [ParentID] BIGINT REFERENCES [GeoDivision]([GeoDivisionID]) ON DELETE NO ACTION,
    [ÇountryCode] CHAR(2) NOT NULL REFERENCES [Country](iso_alpha2),
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
	CONSTRAINT [DF_User_Active] DEFAULT (0) FOR [Active]
);
GO

CREATE TABLE [dbo].[Category](
	[CategoryID] INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(25) NOT NULL,
	[Description] NVARCHAR(80) NULL,
	[Active] BIT NOT NULL,
	
	CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryID]),
	CONSTRAINT [DF_User_Active] DEFAULT (0) FOR [Active]
 );
 GO

CREATE TABLE [Product](
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

CREATE TABLE [Sale](
	[SaleID] INT IDENTITY(1,1) NOT NULL,
	[SaleDate] DATETIME2 NOT NULL,
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
	CONSTRAINT [DF_Sale_SaleDate] DEFAULT sysutcdatetime() FOR [SaleDate],
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

CREATE TABLE [SaleDetail] (
	[SaleDetailID] INT IDENTITY(1,1),
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