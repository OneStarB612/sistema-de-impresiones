USE DeTodo3D;

CREATE NONCLUSTERED INDEX IX_UserRoles_RoleID ON dbo.UserRoles(RoleID);
GO

CREATE NONCLUSTERED INDEX IX_UserClaim_ClaimID ON dbo.UserClaim(ClaimID);
GO

CREATE NONCLUSTERED INDEX IX_RoleClaim_ClaimID ON dbo.RoleClaim(ClaimID);
GO


CREATE INDEX IX_Product_CurrencyCode ON dbo.[Product](CurrencyCode);
GO

-- FILTERED UNIQUE INDEXES (Handles Multiple NULLs safely)

-- Enforces unique emails only for records where an email exists
CREATE UNIQUE NONCLUSTERED INDEX UX_Customer_Email_Filtered
ON Customer (Email)
WHERE Email IS NOT NULL;
GO

-- Enforces unique phone numbers only for records where a phone number exists
CREATE UNIQUE NONCLUSTERED INDEX UX_Customer_Phone_Filtered
ON Customer (PhoneNumber)
WHERE PhoneNumber IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_sales_payments_header ON SalePayment([SaleID]);
GO

CREATE NONCLUSTERED INDEX IX_shipments_sales_header ON Shipment([SaleID]);
GO

CREATE NONCLUSTERED INDEX IX_shipment_items_shipment ON ShipmentItem(ShipmentID);