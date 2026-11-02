USE MorisakiBookshop;
GO

-- 0038_reports_sales_breakdown.sql
-- dbo.Reports_SalesBreakdown for the admin reports page: which genres and which authors sold best in a period.
-- Same meaning of "sale" as dbo.Reports_Sales (0030): orders in the status Paid, Packed, Shipped or Delivered,
-- counted by the day the order was placed. The amount here is the price of the BOOKS (unit price at purchase time
-- x copies), so it does not include shipping or discount codes and is NOT the same number as the revenue card.
-- Needs 0030. Safe to run more than once.

-- @FromDate / @ToDate are UTC; @ToDate is exclusive (the day after the last wanted day).
-- Result set 1: sales per genre (best first, at most 20). Result set 2: sales per author (best first, at most 20).
CREATE OR ALTER PROCEDURE dbo.Reports_SalesBreakdown
    @FromDate DATETIME2(0),
    @ToDate   DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Lines TABLE (BookId INT NOT NULL, Quantity INT NOT NULL, Amount DECIMAL(18,0) NOT NULL);

    INSERT INTO @Lines (BookId, Quantity, Amount)
    SELECT l.BookId, l.Quantity, l.UnitPrice * l.Quantity
    FROM dbo.OrderLines AS l
    INNER JOIN dbo.Orders AS o ON o.Id = l.OrderId
    WHERE o.CreatedAt >= @FromDate
      AND o.CreatedAt < @ToDate
      AND o.Status IN (N'Paid', N'Packed', N'Shipped', N'Delivered');

    SELECT TOP (20)
        b.Genre,
        SUM(x.Quantity) AS Quantity,
        SUM(x.Amount) AS Revenue
    FROM @Lines AS x
    INNER JOIN dbo.Books AS b ON b.Id = x.BookId
    GROUP BY b.Genre
    ORDER BY SUM(x.Amount) DESC, b.Genre;

    SELECT TOP (20)
        a.Id AS AuthorId,
        a.Name,
        SUM(x.Quantity) AS Quantity,
        SUM(x.Amount) AS Revenue
    FROM @Lines AS x
    INNER JOIN dbo.Books AS b ON b.Id = x.BookId
    INNER JOIN dbo.Authors AS a ON a.Id = b.AuthorId
    GROUP BY a.Id, a.Name
    ORDER BY SUM(x.Amount) DESC, a.Id;
END
GO
