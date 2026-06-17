USE DeTodo3D;

CREATE TABLE [dbo].[Country] (
    [ISOAlpha2] CHAR(2) NOT NULL, -- e.g., 'US', 'FR', 'NI'
    [ISOAlpha3] CHAR(3) NOT NULL UNIQUE, -- e.g., 'USA', 'FRA', 'NIC'
    [ISONumeric] CHAR(3) NOT NULL UNIQUE, -- e.g., '840', '250', '558'
    [CommonName] VARCHAR(100) NOT NULL,
    [FormalName] VARCHAR(150),

	CONSTRAINT [PK_Country] PRIMARY KEY ([ISOAlpha2])
);
GO

CREATE TABLE dbo.GeoType (
    GeoTypeID INT IDENTITY(1,1) NOT NULL,
    -- ('region', 'state', 'province', 'department', 'county', 'municipality', 'city', 'district', 'autonomous region')
    [Name] NVARCHAR(150) NOT NULL,

    CONSTRAINT [PK_GeoType] PRIMARY KEY (GeoTypeID),
);
GO

CREATE TABLE [dbo].[GeoDivision] (
    [GeoDivisionID] BIGINT IDENTITY(1,1) NOT NULL,
    [ParentID] BIGINT REFERENCES [GeoDivision]([GeoDivisionID]) ON DELETE NO ACTION,
    [ÇountryCode] CHAR(2) NOT NULL REFERENCES [Country]([ISOAlpha2]),
    [GeoTypeID] INT NOT NULL,
    [ISOSubDivisionCode] VARCHAR(10), -- e.g., 'US-CA' for California, 'NI-MN' for Managua
    [Name] NVARCHAR(150) NOT NULL,
    
	CONSTRAINT [PK_GeoDivisionID] PRIMARY KEY ([GeoDivisionID]),
    CONSTRAINT FK_GeoType FOREIGN KEY ([GeoTypeID]) REFERENCES dbo.GeoType(GeoTypeID)
);
GO



CREATE TABLE [dbo].[User] (
    UserID INT IDENTITY(1,1) NOT NULL,
    Username NVARCHAR(150) NOT NULL,
    Email NVARCHAR(256) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL, -- Store salted hashes only
    [Active] BIT NOT NULL CONSTRAINT DF_Users_Active DEFAULT (1),
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
GO

CREATE TABLE [dbo].[Supplier] (
    [SupplierID] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [ContactEmail] NVARCHAR(100) NULL,
    [Active] BIT NOT NULL CONSTRAINT [DF_Suppliers_Active] DEFAULT (1) FOR [Active],
    
    
    CONSTRAINT [PK_Supplier] PRIMARY KEY ([SupplierID]),
    CONSTRAINT [UQ_Suppliers_Name] UNIQUE ([Name]),
);

CREATE TABLE [dbo].[Category](
	[CategoryID] INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(25) NOT NULL,
	[Description] NVARCHAR(80) NULL,
	[Active] BIT NOT NULL CONSTRAINT [DF_User_Active] DEFAULT (1) FOR [Active],
	
	CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryID]),
	
 );
 GO

 CREATE TABLE [dbo].[Material] (
    [MaterialID] INT IDENTITY(1,1) NOT NULL,
    [SKU] NVARCHAR(50) NOT NULL,
    [MaterialName] NVARCHAR(150) NOT NULL,
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
	[Active] BIT NOT NULL CONSTRAINT [DF_Product_Active] DEFAULT (1) FOR [Active],
	[CategoryID] INT NULL,
	[UnitPrice] DECIMAL(12,2) NULL CONSTRAINT [DF_Product_UnitPrice]  DEFAULT (0) FOR [UnitPrice],
	[UnitCost] DECIMAL(12,2) NULL CONSTRAINT [DF_Product_UnitCost]  DEFAULT (0) FOR [UnitCost],
	[Stock] INT NULL CONSTRAINT [DF_Product_Stock]  DEFAULT (0) FOR [Stock],
	[Discontinued] BIT NOT NULL CONSTRAINT [DF_Product_Discontinued]  DEFAULT (0) FOR [Discontinued],
	
	CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID]),
	CONSTRAINT [CK_Product_UnitPrice] CHECK  ([UnitPrice] >= 0),
	CONSTRAINT [CK_Product_UnitCost] CHECK  ([UnitCost] >= 0),
	CONSTRAINT [CK_Product_Stock] CHECK  ([Stock] >= 0),

	
	CONSTRAINT [FK_Product_Category] FOREIGN KEY([CategoryID]) REFERENCES [dbo].[Category] ([CategoryID])

);
GO

CREATE TABLE dbo.[Status] (
    [StatusID] INT IDENTITY(1,1) NOT NULL,
    [Name] VARCHAR(50) NOT NULL,
    [Active] BIT NOT NULL CONSTRAINT [DF_Status_Active] DEFAULT (1) FOR [Active],
    
    CONSTRAINT PK_Status PRIMARY KEY  ([StatusID]),
    CONSTRAINT UQ_Status_Name  UNIQUE([Name])

);

-- ISO 4217 Currency Definition Table
CREATE TABLE dbo.Currency (
    ISOAlpha3 CHAR(3) NOT NULL, -- Alpha-3 code (e.g., 'USD', 'EUR')
    NumericCode CHAR(3) NOT NULL, -- Numeric code (e.g., '840')
    [Name] NVARCHAR(50) NOT NULL,
    [Symbol] NVARCHAR(10) NOT NULL,
    FractionalDigits INT NOT NULL CONSTRAINT DF_Currency_Digits DEFAULT 2,
    [Active] BIT NOT NULL CONSTRAINT DF_Currency_Active DEFAULT 1,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Currency_CreatedAt DEFAULT (SYSUTCDATETIME()),
    
    CONSTRAINT PK_Currency PRIMARY KEY (ISOAlpha3),
    CONSTRAINT UQ_Currency_Numeric UNIQUE (NumericCode)
);
GO

-- Payment Methods Definition Table
CREATE TABLE dbo.PaymentMethod (
    PaymentMethodID INT IDENTITY(1,1) NOT NULL,
    [Type] NVARCHAR(20) NOT NULL, -- Unique identifier (e.g., 'CREDIT_CARD', 'CASH')
    [Name] NVARCHAR(50) NOT NULL,
    [Active] BIT NOT NULL CONSTRAINT DF_Currency_Active DEFAULT 1,
    RequiresReconciliation BIT NOT NULL CONSTRAINT DF_PaymentMethods_Reconciliation DEFAULT 0,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PaymentMethods_CreatedAt DEFAULT (SYSUTCDATETIME()),
    
    CONSTRAINT PK_PaymentMethod PRIMARY KEY (PaymentMethodID), 
    CONSTRAINT UQ_PaymentMethod_Type UNIQUE([Type])
);
GO

CREATE TABLE [dbo].[Sale](
	[SaleID] BIGINT IDENTITY(1,1) NOT NULL,
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
	[SaleID] BIGINT NOT NULL,
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

CREATE TABLE dbo.SalePayment (
    SalePaymentID BIGINT IDENTITY(1,1) NOT NULL,
    [SaleID] BIGINT NOT NULL,
    PaymentMethodID INT NOT NULL,
    CurrencyID CHAR(3) NOT NULL,
    ExchangeRateUsed DECIMAL(18, 6) NOT NULL CONSTRAINT DF_sales_payments_rate DEFAULT 1.000000,
    AmountInPaymentCurrency DECIMAL(18, 4) NOT NULL, 
    AmountInSaleCurrency DECIMAL(18, 4) NOT NULL,  
    PaymentDate DATETIME2(3) NOT NULL CONSTRAINT DF_SalePayment_PaymentDate DEFAULT (SYSUTCDATETIME()),
    --transaction_reference NVARCHAR(100) NULL,
    
    CONSTRAINT PK_SalePayment PRIMARY KEY CLUSTERED (SalePaymentID),
    CONSTRAINT FK_SalePayment_Sale FOREIGN KEY ([SaleID]) REFERENCES Sale([SaleID]),
    CONSTRAINT FK_SalePayment_Method FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethod(PaymentMethodID),
    CONSTRAINT FK_SalePayment_Currency FOREIGN KEY (CurrencyID) REFERENCES Currency(ISOAlpha3),
    CONSTRAINT CHK_SalePayment_AMT CHECK (AmountInPaymentCurrency > 0)
);

-- CREATE NONCLUSTERED INDEX IX_sales_payments_header ON SalePayment([SaleID]);

CREATE TABLE dbo.Shipment (
    ShipmentID BIGINT IDENTITY(1,1) NOT NULL,
    [SaleID] BIGINT NOT NULL,
    StatusID INT NOT NULL, 
    CostResponsibility VARCHAR(15) NOT NULL, 
    CurrencyCode CHAR(3) NOT NULL,
    ExchangeRateUsed DECIMAL(18, 6) NOT NULL CONSTRAINT DF_Shipment_Rate DEFAULT 1.000000,
    ActualCarrierCost DECIMAL(18, 4) NOT NULL CONSTRAINT DF_Shipment_Cost DEFAULT 0.0000, 
    CustomerShippingFee DECIMAL(18, 4) NOT NULL CONSTRAINT DF_Shipment_Fee DEFAULT 0.0000,
    ShippedAt DATETIME2(3) NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PaymentMethods_CreatedAt DEFAULT (SYSUTCDATETIME()),
    
    CONSTRAINT PK_Shipment PRIMARY KEY (ShipmentID),
    CONSTRAINT FK_Shipment_Sale FOREIGN KEY ([SaleID]) REFERENCES dbo.Sale([SaleID]),
    CONSTRAINT FK_Shipment_Currency FOREIGN KEY (CurrencyCode) REFERENCES dbo.Currency(ISOAlpha3),
    CONSTRAINT CHK_Shipment_Responsibility CHECK (CostResponsibility IN ('CUSTOMER', 'COMPANY'))
);

--CREATE NONCLUSTERED INDEX IX_shipments_sales_header ON Shipment([SaleID]);


CREATE TABLE ShipmentItem (
    ShipmentItemID BIGINT IDENTITY(1,1) NOT NULL,
    ShipmentID BIGINT NOT NULL,
    [SaleDetailID] BIGINT NOT NULL,
    quantity_shipped INT NOT NULL,
    
    CONSTRAINT PK_ShipmentItem PRIMARY KEY CLUSTERED (ShipmentItemID),
    CONSTRAINT FK_ShipmentItem_Shipment FOREIGN KEY (ShipmentID) REFERENCES Shipment(ShipmentID) ON DELETE CASCADE,
    CONSTRAINT FK_ShipmentItem_Detail FOREIGN KEY ([SaleDetailID]) REFERENCES dbo.[SaleDetail]([SaleDetailID]),
    CONSTRAINT CHK_ShipmentItem_Qty CHECK (quantity_shipped > 0)
);

--CREATE NONCLUSTERED INDEX IX_shipment_items_shipment ON ShipmentItem(ShipmentID);