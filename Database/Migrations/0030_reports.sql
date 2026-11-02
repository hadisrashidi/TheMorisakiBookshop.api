USE MorisakiBookshop;
GO

-- 0030_reports.sql
-- Reports for the admin API: dbo.Reports_Sales (summary, sales per day, best-selling books of a period) and
-- dbo.Reports_LowStock (books that are almost or fully sold out).
-- "Sales" = orders in the status Paid, Packed, Shipped or Delivered, counted by the day the order was placed
-- (PendingPayment and Cancelled orders are NOT revenue; they are only counted separately).
-- The revenue is the order total, shipping included. Days are Iran days (UTC + 03:30).
-- Needs 0016. Safe to run more than once.

-- @FromDate / @ToDate are UTC; @ToDate is exclusive (the day after the last wanted day).
-- Result set 1: one summary row. Result set 2: one row per day that has sales. Result set 3: the 10 best-selling books.
CREATE OR ALTER PROCEDURE dbo.Reports_Sales
    @FromDate DATETIME2(0),
    @ToDate   DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Counted TABLE (OrderId INT NOT NULL PRIMARY KEY, Total DECIMAL(18,0) NOT NULL, CreatedAt DATETIME2(0) NOT NULL);

    INSERT INTO @Counted (OrderId, Total, CreatedAt)
    SELECT Id, Total, CreatedAt
    FROM dbo.Orders
    WHERE CreatedAt >= @FromDate
      AND CreatedAt < @ToDate
      AND Status IN (N'Paid', N'Packed', N'Shipped', N'Delivered');

    SELECT
        ISNULL((SELECT SUM(Total) FROM @Counted), 0) AS Revenue,
        (SELECT COUNT(*) FROM @Counted) AS OrdersCount,
        ISNULL((SELECT SUM(l.Quantity)
                FROM dbo.OrderLines AS l
                INNER JOIN @Counted AS c ON c.OrderId = l.OrderId), 0) AS BooksSold,
        (SELECT COUNT(*) FROM dbo.Orders
         WHERE CreatedAt >= @FromDate AND CreatedAt < @ToDate AND Status = N'PendingPayment') AS PendingCount,
        ISNULL((SELECT SUM(Total) FROM dbo.Orders
                WHERE CreatedAt >= @FromDate AND CreatedAt < @ToDate AND Status = N'PendingPayment'), 0) AS PendingAmount,
        (SELECT COUNT(*) FROM dbo.Orders
         WHERE CreatedAt >= @FromDate AND CreatedAt < @ToDate AND Status = N'Cancelled') AS CancelledCount,
        (SELECT COUNT(*) FROM dbo.Users
         WHERE CreatedAt >= @FromDate AND CreatedAt < @ToDate AND Role = N'Customer') AS NewCustomers;

    SELECT
        CAST(DATEADD(MINUTE, 210, CreatedAt) AS DATE) AS Day,
        SUM(Total) AS Revenue,
        COUNT(*) AS OrdersCount
    FROM @Counted
    GROUP BY CAST(DATEADD(MINUTE, 210, CreatedAt) AS DATE)
    ORDER BY Day;

    SELECT TOP (10)
        l.BookId,
        MAX(l.Title) AS Title,
        SUM(l.Quantity) AS Quantity,
        SUM(l.UnitPrice * l.Quantity) AS Revenue
    FROM dbo.OrderLines AS l
    INNER JOIN @Counted AS c ON c.OrderId = l.OrderId
    GROUP BY l.BookId
    ORDER BY SUM(l.Quantity) DESC, SUM(l.UnitPrice * l.Quantity) DESC, l.BookId;
END
GO

-- Shown books with @Threshold copies or fewer left, fewest first (at most 100 rows).
CREATE OR ALTER PROCEDURE dbo.Reports_LowStock
    @Threshold INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF @Threshold < 0
    BEGIN
        SET @Threshold = 0;
    END

    IF @Threshold > 1000
    BEGIN
        SET @Threshold = 1000;
    END

    SELECT TOP (100) b.Id, b.Title, ISNULL(a.Name, N'') AS AuthorName, b.Stock
    FROM dbo.Books AS b
    LEFT JOIN dbo.Authors AS a ON a.Id = b.AuthorId
    WHERE b.IsActive = 1
      AND b.Stock <= @Threshold
    ORDER BY b.Stock, b.Title;
END
GO
