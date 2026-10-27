USE MorisakiBookshop;
GO

-- 0020_addresses.sql
-- Creates dbo.Addresses (the saved delivery addresses of a user) and its procedures.
-- Exactly one address per user is the default; the procedures keep that rule.
-- Safe to run more than once.

IF OBJECT_ID(N'dbo.Addresses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Addresses
    (
        Id          INT            IDENTITY(1,1) NOT NULL,
        UserId      INT            NOT NULL,
        Title       NVARCHAR(50)   NOT NULL,
        Recipient   NVARCHAR(100)  NOT NULL,
        Phone       NVARCHAR(11)   NOT NULL,
        City        NVARCHAR(50)   NOT NULL,
        FullAddress NVARCHAR(400)  NOT NULL,
        PostalCode  NVARCHAR(10)   NOT NULL CONSTRAINT DF_Addresses_PostalCode DEFAULT (N''),
        IsDefault   BIT            NOT NULL CONSTRAINT DF_Addresses_IsDefault DEFAULT (0),
        CONSTRAINT PK_Addresses PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_Addresses_Users', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Addresses
        ADD CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (Id) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Addresses_UserId' AND object_id = OBJECT_ID(N'dbo.Addresses'))
BEGIN
    CREATE INDEX IX_Addresses_UserId ON dbo.Addresses (UserId);
END
GO

-- Default address first, then the oldest.
CREATE OR ALTER PROCEDURE dbo.Addresses_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, Recipient, Phone, City, FullAddress, PostalCode, IsDefault
    FROM dbo.Addresses
    WHERE UserId = @UserId
    ORDER BY IsDefault DESC, Id;
END
GO

-- The first address of a user becomes the default automatically.
CREATE OR ALTER PROCEDURE dbo.Addresses_Insert
    @UserId      INT,
    @Title       NVARCHAR(50),
    @Recipient   NVARCHAR(100),
    @Phone       NVARCHAR(11),
    @City        NVARCHAR(50),
    @FullAddress NVARCHAR(400),
    @PostalCode  NVARCHAR(10),
    @IsDefault   BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.Addresses WHERE UserId = @UserId)
    BEGIN
        SET @IsDefault = 1;
    END

    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.Addresses SET IsDefault = 0 WHERE UserId = @UserId;
    END

    INSERT INTO dbo.Addresses (UserId, Title, Recipient, Phone, City, FullAddress, PostalCode, IsDefault)
    VALUES (@UserId, @Title, @Recipient, @Phone, @City, @FullAddress, @PostalCode, @IsDefault);

    DECLARE @NewId INT = CAST(SCOPE_IDENTITY() AS INT);

    COMMIT TRANSACTION;

    SELECT @NewId AS Id;
END
GO

-- Only the owner can change an address (WHERE UserId). AffectedRows 0 = not found / not yours.
CREATE OR ALTER PROCEDURE dbo.Addresses_Update
    @Id          INT,
    @UserId      INT,
    @Title       NVARCHAR(50),
    @Recipient   NVARCHAR(100),
    @Phone       NVARCHAR(11),
    @City        NVARCHAR(50),
    @FullAddress NVARCHAR(400),
    @PostalCode  NVARCHAR(10),
    @IsDefault   BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.Addresses WHERE Id = @Id AND UserId = @UserId)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS AffectedRows;
        RETURN;
    END

    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.Addresses SET IsDefault = 0 WHERE UserId = @UserId;
    END

    -- Unchecking "default" on the current default does nothing: another one must be chosen instead.
    UPDATE dbo.Addresses
    SET Title = @Title,
        Recipient = @Recipient,
        Phone = @Phone,
        City = @City,
        FullAddress = @FullAddress,
        PostalCode = @PostalCode,
        IsDefault = CASE WHEN @IsDefault = 1 THEN 1 ELSE IsDefault END
    WHERE Id = @Id AND UserId = @UserId;

    COMMIT TRANSACTION;

    SELECT 1 AS AffectedRows;
END
GO

-- Deleting the default makes the oldest remaining address the new default.
CREATE OR ALTER PROCEDURE dbo.Addresses_Delete
    @Id     INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @WasDefault BIT = (SELECT IsDefault FROM dbo.Addresses WHERE Id = @Id AND UserId = @UserId);

    IF @WasDefault IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS AffectedRows;
        RETURN;
    END

    DELETE FROM dbo.Addresses WHERE Id = @Id AND UserId = @UserId;

    IF @WasDefault = 1
    BEGIN
        UPDATE dbo.Addresses
        SET IsDefault = 1
        WHERE Id = (SELECT TOP (1) Id FROM dbo.Addresses WHERE UserId = @UserId ORDER BY Id);
    END

    COMMIT TRANSACTION;

    SELECT 1 AS AffectedRows;
END
GO

CREATE OR ALTER PROCEDURE dbo.Addresses_SetDefault
    @Id     INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.Addresses WHERE Id = @Id AND UserId = @UserId)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS AffectedRows;
        RETURN;
    END

    UPDATE dbo.Addresses SET IsDefault = CASE WHEN Id = @Id THEN 1 ELSE 0 END WHERE UserId = @UserId;

    COMMIT TRANSACTION;

    SELECT 1 AS AffectedRows;
END
GO
