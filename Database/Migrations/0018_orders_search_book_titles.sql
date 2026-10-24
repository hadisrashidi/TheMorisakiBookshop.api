USE MorisakiBookshop;
GO

-- 0018_orders_search_book_titles.sql
-- dbo.Orders_Search now also returns BookTitles (the titles of the ordered books, joined with "،")
-- so the admin list can show what was bought, and the search text also matches a book title.
-- Replaces the procedure of 0017 (same parameters, one extra column). Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Orders_Search
    @Query    NVARCHAR(100) = NULL,   -- order number, recipient name, recipient mobile, account mobile or a book title
    @Status   NVARCHAR(30)  = NULL,   -- NULL = all statuses
    @Page     INT           = 1,
    @PageSize INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1
    BEGIN
        SET @Page = 1;
    END

    IF @PageSize < 1
    BEGIN
        SET @PageSize = 1;
    END

    IF @PageSize > 50
    BEGIN
        SET @PageSize = 50;
    END

    SET @Query = NULLIF(LTRIM(RTRIM(REPLACE(ISNULL(@Query, N''), N'#', N''))), N'');

    DECLARE @OrderNumber INT = TRY_CAST(@Query AS INT);

    -- Result set 1: totals for the pager (values actually used).
    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE (@Status IS NULL OR o.Status = @Status)
      AND (@Query IS NULL
           OR o.Id = @OrderNumber
           OR o.RecipientName LIKE N'%' + @Query + N'%'
           OR o.RecipientMobile LIKE N'%' + @Query + N'%'
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id AND l.Title LIKE N'%' + @Query + N'%'));

    -- Result set 2: the requested page, newest first.
    SELECT
        o.Id,
        o.Status,
        o.Total,
        o.RecipientName,
        o.RecipientMobile,
        o.CreatedAt,
        ISNULL((SELECT SUM(l.Quantity) FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id), 0) AS ItemsCount,
        ISNULL((SELECT STRING_AGG(CAST(l.Title AS NVARCHAR(MAX)), N'، ') WITHIN GROUP (ORDER BY l.Id)
                FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id), N'') AS BookTitles
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE (@Status IS NULL OR o.Status = @Status)
      AND (@Query IS NULL
           OR o.Id = @OrderNumber
           OR o.RecipientName LIKE N'%' + @Query + N'%'
           OR o.RecipientMobile LIKE N'%' + @Query + N'%'
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id AND l.Title LIKE N'%' + @Query + N'%'))
    ORDER BY o.CreatedAt DESC, o.Id DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO
