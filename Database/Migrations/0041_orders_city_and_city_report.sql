USE MorisakiBookshop;
GO

-- 0041_orders_city_and_city_report.sql
-- The city of the delivery address becomes its own column (Orders.City) so the admin can report sales per city:
--   * Orders.City: Persian letters (ي -> ی, ك -> ک), trimmed; NULL = unknown.
--   * Old orders are filled from their address text: the shop always wrote the address as "<city>، <rest>"
--     (the text before the first "،"). An old order without that comma stays NULL ("unknown" in the report).
--   * dbo.Orders_Place (last defined in 0032) also saves the city of the checkout address. Nothing else changes.
--   * dbo.Reports_SalesByCity: orders and revenue per city for a period (same meaning of "sale" as 0030: Paid, Packed,
--     Shipped, Delivered, by the day the order was placed; revenue = order total, shipping included).
-- Needs 0032 and 0030. Safe to run more than once.

IF COL_LENGTH(N'dbo.Orders', N'City') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD City NVARCHAR(100) NULL;
END
GO

-- Fills only the orders that have no city yet, so running the script again changes nothing.
UPDATE dbo.Orders
SET City = NULLIF(LTRIM(RTRIM(LEFT(REPLACE(REPLACE(Address, N'ي', N'ی'), N'ك', N'ک'), CASE WHEN CHARINDEX(N'،', Address) > 1 THEN CHARINDEX(N'،', Address) - 1 ELSE 0 END))), N'')
WHERE City IS NULL
  AND CHARINDEX(N'،', Address) > 1
  AND CHARINDEX(N'،', Address) <= 101;
GO

-- Same as 0032, plus the city is saved in the order.
CREATE OR ALTER PROCEDURE dbo.Orders_Place
    @UserId           INT,
    @RecipientName    NVARCHAR(100),
    @RecipientMobile  NVARCHAR(11),
    @Address          NVARCHAR(500),
    @PostalCode       NVARCHAR(10),
    @ShippingMethodId INT,
    @City             NVARCHAR(100),
    @Lines            NVARCHAR(MAX),  -- JSON: [{"BookId":1,"Quantity":2}]
    @DiscountCode     NVARCHAR(50) = NULL   -- optional discount code
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

    DECLARE @IsTehran BIT = CASE WHEN LTRIM(RTRIM(REPLACE(REPLACE(@City, N'ي', N'ی'), N'ك', N'ک'))) = N'تهران' THEN 1 ELSE 0 END;
    DECLARE @MethodName NVARCHAR(100);
    DECLARE @MethodPrice DECIMAL(18,0);
    DECLARE @MethodFreeAbove DECIMAL(18,0);

    SELECT @MethodName = Name, @MethodPrice = Price, @MethodFreeAbove = FreeAbove
    FROM dbo.ShippingMethods
    WHERE Id = @ShippingMethodId
      AND IsActive = 1
      AND (@IsTehran = 1 OR TehranOnly = 0);

    IF @MethodName IS NULL
    BEGIN
        SELECT 0 AS OrderId, N'ShippingMethodInvalid' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
        RETURN;
    END

    DECLARE @ShippingCost DECIMAL(18,0);
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

    -- Shipping is free from FreeAbove by the price of the BOOKS (before the discount code).
    SET @ShippingCost = CASE WHEN @MethodFreeAbove IS NOT NULL AND @Subtotal >= @MethodFreeAbove THEN 0 ELSE @MethodPrice END;

    DECLARE @CodeText NVARCHAR(50) = NULLIF(UPPER(LTRIM(RTRIM(ISNULL(@DiscountCode, N'')))), N'');
    DECLARE @CodeId INT = NULL;
    DECLARE @DiscountAmount DECIMAL(18,0) = 0;

    IF @CodeText IS NOT NULL
    BEGIN
        -- Locks the code row: two orders at the same moment cannot both take its last use.
        SELECT @CodeId = Id FROM dbo.DiscountCodes WITH (UPDLOCK, HOLDLOCK) WHERE Code = @CodeText;

        DECLARE @Check TABLE (CodeId INT NOT NULL, Reason NVARCHAR(30) NOT NULL, DiscountAmount DECIMAL(18,0) NOT NULL);

        INSERT INTO @Check (CodeId, Reason, DiscountAmount)
        EXEC dbo.DiscountCodes_Check @Code = @CodeText, @UserId = @UserId, @Subtotal = @Subtotal;

        DECLARE @Reason NVARCHAR(30);

        SELECT @Reason = Reason, @CodeId = CodeId, @DiscountAmount = DiscountAmount FROM @Check;

        IF @Reason <> N'Ok'
        BEGIN
            ROLLBACK TRANSACTION;   -- gives the stock back

            SELECT 0 AS OrderId, N'DiscountInvalid' AS Problem, 0 AS ProblemBookId, @Reason AS ProblemTitle;
            RETURN;
        END
    END

    INSERT INTO dbo.Orders (UserId, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode, ShippingMethodName, DiscountCode, DiscountAmount, City)
    VALUES (@UserId, @Subtotal, @ShippingCost, @Subtotal - @DiscountAmount + @ShippingCost, @RecipientName, @RecipientMobile, @Address, @PostalCode, @MethodName, @CodeText, @DiscountAmount,
            NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(@City, N'ي', N'ی'), N'ك', N'ک'))), N''));

    SET @OrderId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.OrderStatusHistory (OrderId, Status) VALUES (@OrderId, N'PendingPayment');

    IF @CodeId IS NOT NULL
    BEGIN
        INSERT INTO dbo.DiscountCodeUses (CodeId, UserId, OrderId, DiscountAmount) VALUES (@CodeId, @UserId, @OrderId, @DiscountAmount);
    END

    INSERT INTO dbo.OrderLines (OrderId, BookId, Title, Image, UnitPrice, Quantity)
    SELECT @OrderId, b.Id, b.Title, b.Image, b.Price, w.Quantity
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    COMMIT TRANSACTION;

    SELECT @OrderId AS OrderId, N'' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
END
GO
-- @FromDate / @ToDate are UTC; @ToDate is exclusive (the day after the last wanted day).
-- One row per city (best revenue first, at most 20); orders without a known city are one row with an empty City.
CREATE OR ALTER PROCEDURE dbo.Reports_SalesByCity
    @FromDate DATETIME2(0),
    @ToDate   DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (20)
        ISNULL(City, N'') AS City,
        COUNT(*) AS OrdersCount,
        SUM(Total) AS Revenue
    FROM dbo.Orders
    WHERE CreatedAt >= @FromDate
      AND CreatedAt < @ToDate
      AND Status IN (N'Paid', N'Packed', N'Shipped', N'Delivered')
    GROUP BY ISNULL(City, N'')
    ORDER BY SUM(Total) DESC, ISNULL(City, N'');
END
GO
