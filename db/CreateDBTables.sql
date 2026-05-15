USE master;
GO

DROP DATABASE IF EXISTS DeTodo3D;
GO
CREATE DATABASE DeTodo3D;
GO

USE DeTodo3D;
GO

/*
como almacenar direccion?
campo o tabla?
pais > provincia > municipio o partido > localidades

direccion para envios: calle, numero, localidad, provincia codigo postal

direccion para ML:
direccion (un campo) si, provincia o ciudad, localidad si
*/
/*
CREATE TABLE [Supplier](
	SupplierID INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(30) NOT NULL,
	--direccion?
	CONSTRAINT [PK_Supplier] PRIMARY KEY (SupplierID)
);
GO
*/

CREATE TABLE [User] (
    userID INT IDENTITY(1,1) NOT NULL,
    [Name] VARCHAR(100) NOT NULL,
    [Lastname] VARCHAR(100) NOT NULL,
    
    CONSTRAINT [PK_User] PRIMARY KEY (UserID),
);
GO

CREATE TABLE [dbo].[Category](
	[CategoryID] INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(20) NOT NULL,
	[Description] NVARCHAR(80) NULL,
	
	CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryID])
 );
 GO

CREATE TABLE [Product](
	ProductID INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(80) NOT NULL,
	CategoryID INT NULL,
	UnitPrice DECIMAL(12,2) NULL,
	UnitCost DECIMAL(12,2) NULL,
	Stock INT NULL,
	Discontinued BIT NOT NULL,
	
	CONSTRAINT [PK_Product] PRIMARY KEY ([ProductID]),
	CONSTRAINT [DF_Product_UnitPrice]  DEFAULT (0) FOR [UnitPrice],
	CONSTRAINT [DF_Product_UnitCost]  DEFAULT (0) FOR [UnitCost],
	CONSTRAINT [DF_Product_Stock_Default]  DEFAULT (0) FOR [Stock],
	CONSTRAINT [DF_Product_Discontinued]  DEFAULT (0) FOR [Discontinued],
	CONSTRAINT [CK_Product_UnitPrice] CHECK  ([UnitPrice] >= 0),
	CONSTRAINT [CK_Product_UnitCost] CHECK  ([UnitCost] >= 0),
	CONSTRAINT [CK_Product_StockT] CHECK  ([Stock] >= 0),

	
	CONSTRAINT [FK_Product_Category] FOREIGN KEY([CategoryID]) REFERENCES [dbo].[Category] ([CategoryID])

);
GO

CREATE TABLE [Sale](
	SaleID INT IDENTITY(1,1) NOT NULL,
	SaleDate DATETIME2 NOT NULL,
	UserID INT NOT NULL,
	DiscountAmount DECIMAL(18,4) NOT NULL,
	DiscountPercentage DECIMAL(5,2) NOT NULL,
	TaxAmount DECIMAL(18, 4) NOT NULL,
	CurrencyCode NVARCHAR(3) NOT NULL,
	Total DECIMAL(18,4),
	Observation VARCHAR(150) NULL,

	CONSTRAINT PK_Sale PRIMARY KEY ([SaleID]),
	CONSTRAINT DF_Sale_SaleDate DEFAULT sysutcdatetime() FOR [SaleDate],
	CONSTRAINT DF_Sale_DiscountPercentage DEFAULT (0) FOR [DiscountPercentage],
	CONSTRAINT CK_Sale_DiscountPercentage CHECK ([DiscountPercentage] >= 0),
	CONSTRAINT DF_Sale_DiscountAmount DEFAULT (0) FOR [DiscountAmount],
	CONSTRAINT CK_Sale_DiscountAmount CHECK ([DiscountAmount] >= 0),
	CONSTRAINT DF_Sale_TaxAmount DEFAULT (0) FOR [TaxAmount],
	CONSTRAINT CK_Sale_TaxAmount CHECK ([TaxAmount] >= 0),
	CONSTRAINT DF_Sale_Total DEFAULT (0) FOR [Total],
	CONSTRAINT CK_Sale_Total CHECK ([Total] >= 0),

	CONSTRAINT FK_UserID FOREIGN KEY ([UserID]) REFERENCES [dbo].[User] ([userID])
);
GO

