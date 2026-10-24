USE MorisakiBookshop;
GO

-- 0016_orders_procedures.sql
-- dbo.Orders_Place: checks stock, decreases stock, creates the order and its lines in ONE transaction.
-- dbo.Orders_GetByUserId: the orders of one customer (result set 1) and their lines (result set 2).
-- Run after 0015. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Orders_Place
    @UserId          INT,
    @RecipientName   NVARCHAR(100),
    @RecipientMobile NVARCHAR(11),
    @Address         NVARCHAR(500),
    @PostalCode      NVARCHAR(10),
    @Lines           NVARCHAR(MAX)   -- JSON: [{"BookId":1,"Quantity":2}]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- The same book sent twice becomes one line with the summed quantity.
    DECLARE @Wanted TABLE (BookId INT NOT NULL PRIMARY KEY, Quantity INT NOT NULL);

    INSERT INTO @Wanted (BookId, Quantity)
    SELECT BookId, SUM(Quantity)
    FROM OPENJSON(@Lines)
         WITH (BookId INT '$.BookId', Quantity INT '$.Quantity')
    GROUP BY BookId;

    IF NOT EXISTS (SELECT 1 FROM @Wanted) OR EXISTS (SELECT 1 FROM @Wanted WHERE Quantity <= 0)
    BEGIN
        SELECT 0 AS OrderId, N'EmptyOrder' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
        RETURN;
    END

    DECLARE @ShippingCost DECIMAL(18,0) = 0;   -- no shipping prices yet (phase 4)
    DECLARE @OrderId INT;

    BEGIN TRANSACTION;

    -- One UPDATE takes the stock only of the books that exist, are shown and have enough stock.
    -- If a concurrent order took the last copy, this UPDATE simply skips that book (no negative stock).
    UPDATE b
    SET b.Stock = b.Stock - w.Quantity
    FROM dbo.Books AS b
    INNER JOIN @Wanted AS w ON w.BookId = b.Id
    WHERE b.IsActive = 1
      AND b.Stock >= w.Quantity;

    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @Wanted)
    BEGIN
        ROLLBACK TRANSACTION;   -- gives the stock back

        SELECT TOP (1)
            0 AS OrderId,
            CASE WHEN b.Id IS NULL OR b.IsActive = 0 THEN N'BookNotFound' ELSE N'NotEnoughStock' END AS Problem,
            w.BookId AS ProblemBookId,
            ISNULL(b.Title, N'') AS ProblemTitle
        FROM @Wanted AS w
        LEFT JOIN dbo.Books AS b ON b.Id = w.BookId
        WHERE b.Id IS NULL OR b.IsActive = 0 OR b.Stock < w.Quantity
        ORDER BY w.BookId;

        RETURN;
    END

    DECLARE @Subtotal DECIMAL(18,0);

    SELECT @Subtotal = SUM(b.Price * w.Quantity)
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    INSERT INTO dbo.Orders (UserId, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode)
    VALUES (@UserId, @Subtotal, @ShippingCost, @Subtotal + @ShippingCost, @RecipientName, @RecipientMobile, @Address, @PostalCode);

    SET @OrderId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.OrderLines (OrderId, BookId, Title, Image, UnitPrice, Quantity)
    SELECT @OrderId, b.Id, b.Title, b.Image, b.Price, w.Quantity
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    COMMIT TRANSACTION;

    SELECT @OrderId AS OrderId, N'' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
END
GO

CREATE OR ALTER PROCEDURE dbo.Orders_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Status, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode, TrackingCode, CreatedAt
    FROM dbo.Orders
    WHERE UserId = @UserId
    ORDER BY CreatedAt DESC, Id DESC;

    SELECT l.OrderId, l.BookId, l.Title, l.Image, l.UnitPrice, l.Quantity
    FROM dbo.OrderLines AS l
    INNER JOIN dbo.Orders AS o ON o.Id = l.OrderId
    WHERE o.UserId = @UserId
    ORDER BY l.OrderId, l.Id;
END
GO
