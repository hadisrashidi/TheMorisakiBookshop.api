USE MorisakiBookshop;
GO

-- 0035_books_best_sellers.sql
-- Adds dbo.Books_GetBestSellers for the shop home page.
-- Best sellers = shown books with the most copies sold, counting only orders that are
-- Paid / Packed / Shipped / Delivered (the same meaning of "sale" as the reports).
-- Books that never sold are NOT returned, so a new shop gets an empty list (the UI hides the block).
-- Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Books_GetBestSellers
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Count) b.Id, b.Title, b.AuthorId, b.Price, b.OldPrice, b.Stock,
           CAST(CASE WHEN b.Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           b.IsActive, b.Image, b.Description, b.Genre, b.Language, b.AddedAt
    FROM dbo.Books AS b
    INNER JOIN
    (
        SELECT l.BookId, SUM(l.Quantity) AS Sold
        FROM dbo.OrderLines AS l
        INNER JOIN dbo.Orders AS o ON o.Id = l.OrderId
        WHERE o.Status IN (N'Paid', N'Packed', N'Shipped', N'Delivered')
        GROUP BY l.BookId
    ) AS s ON s.BookId = b.Id
    WHERE b.IsActive = 1
    ORDER BY s.Sold DESC, b.Id;
END
GO
