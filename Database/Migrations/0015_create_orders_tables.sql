USE MorisakiBookshop;
GO

-- 0015_create_orders_tables.sql
-- Creates dbo.Orders (one row per order) and dbo.OrderLines (one row per book in the order).
-- Title, Image and UnitPrice are COPIED into the line at purchase time, so later price or title changes never change an old order.
-- Safe to run more than once.

IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        Id              INT            IDENTITY(1,1) NOT NULL,
        UserId          INT            NOT NULL,
        Status          NVARCHAR(30)   NOT NULL CONSTRAINT DF_Orders_Status DEFAULT (N'PendingPayment'),
        Subtotal        DECIMAL(18,0)  NOT NULL,
        ShippingCost    DECIMAL(18,0)  NOT NULL CONSTRAINT DF_Orders_ShippingCost DEFAULT (0),
        Total           DECIMAL(18,0)  NOT NULL,
        RecipientName   NVARCHAR(100)  NOT NULL,
        RecipientMobile NVARCHAR(11)   NOT NULL,
        Address         NVARCHAR(500)  NOT NULL,
        PostalCode      NVARCHAR(10)   NOT NULL CONSTRAINT DF_Orders_PostalCode DEFAULT (N''),
        TrackingCode    NVARCHAR(50)   NOT NULL CONSTRAINT DF_Orders_TrackingCode DEFAULT (N''),
        CreatedAt       DATETIME2(0)   NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Orders PRIMARY KEY (Id),
        CONSTRAINT CK_Orders_Status CHECK (Status IN (N'PendingPayment', N'Paid', N'Packed', N'Shipped', N'Delivered', N'Cancelled'))
    );
END
GO

IF OBJECT_ID(N'dbo.FK_Orders_Users', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Orders
        ADD CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_UserId' AND object_id = OBJECT_ID(N'dbo.Orders'))
BEGIN
    CREATE INDEX IX_Orders_UserId ON dbo.Orders (UserId);
END
GO

IF OBJECT_ID(N'dbo.OrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderLines
    (
        Id         INT            IDENTITY(1,1) NOT NULL,
        OrderId    INT            NOT NULL,
        BookId     INT            NOT NULL,
        Title      NVARCHAR(200)  NOT NULL,
        Image      NVARCHAR(200)  NOT NULL,
        UnitPrice  DECIMAL(18,0)  NOT NULL,
        Quantity   INT            NOT NULL,
        CONSTRAINT PK_OrderLines PRIMARY KEY (Id),
        CONSTRAINT CK_OrderLines_Quantity CHECK (Quantity > 0)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_OrderLines_Orders', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.OrderLines
        ADD CONSTRAINT FK_OrderLines_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id) ON DELETE CASCADE;
END
GO

IF OBJECT_ID(N'dbo.FK_OrderLines_Books', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.OrderLines
        ADD CONSTRAINT FK_OrderLines_Books FOREIGN KEY (BookId) REFERENCES dbo.Books (Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderLines_OrderId' AND object_id = OBJECT_ID(N'dbo.OrderLines'))
BEGIN
    CREATE INDEX IX_OrderLines_OrderId ON dbo.OrderLines (OrderId);
END
GO
