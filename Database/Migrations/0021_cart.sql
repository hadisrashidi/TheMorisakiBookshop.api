USE MorisakiBookshop;
GO

-- 0021_cart.sql
-- Creates dbo.CartItems (the saved cart of a logged-in user) and its procedures.
-- The cart stores only BookId + Quantity; title, image, price and stock are read from dbo.Books every time,
-- so the cart never shows an old price. At most 20 copies of one book (same limit as an order line).
-- Safe to run more than once.

IF OBJECT_ID(N'dbo.CartItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CartItems
    (
        UserId   INT           NOT NULL,
        BookId   INT           NOT NULL,
        Quantity INT           NOT NULL,
        AddedAt  DATETIME2(0)  NOT NULL CONSTRAINT DF_CartItems_AddedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_CartItems PRIMARY KEY (UserId, BookId),
        CONSTRAINT CK_CartItems_Quantity CHECK (Quantity BETWEEN 1 AND 20)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_CartItems_Users', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.CartItems
        ADD CONSTRAINT FK_CartItems_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (Id) ON DELETE CASCADE;
END
GO

IF OBJECT_ID(N'dbo.FK_CartItems_Books', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.CartItems
        ADD CONSTRAINT FK_CartItems_Books FOREIGN KEY (BookId) REFERENCES dbo.Books (Id) ON DELETE CASCADE;
END
GO

-- Hidden books are left out (they cannot be ordered), in the order they were added.
CREATE OR ALTER PROCEDURE dbo.CartItems_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT b.Id, b.Title, b.Image, b.Price, b.OldPrice, b.Stock, c.Quantity
    FROM dbo.CartItems c
    INNER JOIN dbo.Books b ON b.Id = c.BookId
    WHERE c.UserId = @UserId
      AND b.IsActive = 1
    ORDER BY c.AddedAt, b.Id;
END
GO

-- Sets the quantity of one book. Quantity 0 removes the book from the cart.
-- AffectedRows 0 = the book does not exist or is hidden.
CREATE OR ALTER PROCEDURE dbo.CartItems_SetQuantity
    @UserId   INT,
    @BookId   INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0
    BEGIN
        DELETE FROM dbo.CartItems WHERE UserId = @UserId AND BookId = @BookId;
        SELECT 1 AS AffectedRows;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = @BookId AND IsActive = 1)
    BEGIN
        SELECT 0 AS AffectedRows;
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.CartItems WITH (UPDLOCK, HOLDLOCK)
    SET Quantity = CASE WHEN @Quantity > 20 THEN 20 ELSE @Quantity END
    WHERE UserId = @UserId AND BookId = @BookId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.CartItems (UserId, BookId, Quantity)
        VALUES (@UserId, @BookId, CASE WHEN @Quantity > 20 THEN 20 ELSE @Quantity END);
    END

    COMMIT TRANSACTION;

    SELECT 1 AS AffectedRows;
END
GO

-- Adds the guest cart of the browser to the saved cart right after login.
-- @Lines = JSON [{"BookId":1,"Quantity":2}]. Same book in both carts = quantities added (max 20).
-- Hidden / missing books and quantities below 1 are skipped.
CREATE OR ALTER PROCEDURE dbo.CartItems_Merge
    @UserId INT,
    @Lines  NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    MERGE dbo.CartItems WITH (HOLDLOCK) AS target
    USING
    (
        SELECT @UserId AS UserId, l.BookId, SUM(l.Quantity) AS Quantity
        FROM OPENJSON(@Lines)
             WITH (BookId INT '$.BookId', Quantity INT '$.Quantity') AS l
        INNER JOIN dbo.Books b ON b.Id = l.BookId AND b.IsActive = 1
        WHERE l.Quantity >= 1
        GROUP BY l.BookId
    ) AS source
        ON target.UserId = source.UserId AND target.BookId = source.BookId
    WHEN MATCHED THEN
        UPDATE SET Quantity = CASE WHEN target.Quantity + source.Quantity > 20 THEN 20 ELSE target.Quantity + source.Quantity END
    WHEN NOT MATCHED THEN
        INSERT (UserId, BookId, Quantity)
        VALUES (source.UserId, source.BookId, CASE WHEN source.Quantity > 20 THEN 20 ELSE source.Quantity END);

    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.CartItems_Clear
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.CartItems WHERE UserId = @UserId;
END
GO
