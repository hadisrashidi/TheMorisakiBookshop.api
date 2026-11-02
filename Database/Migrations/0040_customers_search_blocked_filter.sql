USE MorisakiBookshop;
GO

-- 0040_customers_search_blocked_filter.sql
-- dbo.Customers_Search (last defined in 0039) gets an optional @Status filter: all / blocked / active.
-- Old calls keep working (the new parameter is optional). Needs 0039. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Customers_Search
    @Query    NVARCHAR(100) = NULL,   -- part of the name, the mobile number or the e-mail
    @Sort     NVARCHAR(20)  = NULL,   -- 'newest' (default) | 'orders' | 'spent' | 'last_order'
    @Status   NVARCHAR(10)  = NULL,   -- NULL / empty = all | 'blocked' | 'active'
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

    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');
    SET @Status = NULLIF(@Status, N'');

    -- LIKE treats [ % _ as wildcards; wrap them so they are searched as plain characters.
    SET @Query = REPLACE(REPLACE(REPLACE(@Query, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]');

    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize
    FROM dbo.Users AS u
    WHERE u.Role = N'Customer'
      AND (@Status IS NULL
           OR (@Status = N'blocked' AND u.IsBlocked = 1)
           OR (@Status = N'active' AND u.IsBlocked = 0))
      AND (@Query IS NULL
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR u.Name LIKE N'%' + @Query + N'%'
           OR u.Email LIKE N'%' + @Query + N'%');

    SELECT u.Id, u.Name, u.Mobile, u.Email, u.CreatedAt, u.IsBlocked,
           ISNULL(s.OrdersCount, 0) AS OrdersCount,
           ISNULL(s.TotalSpent, 0) AS TotalSpent,
           s.LastOrderAt
    FROM dbo.Users AS u
    LEFT JOIN
    (
        SELECT o.UserId,
               SUM(CASE WHEN o.Status <> N'Cancelled' THEN 1 ELSE 0 END) AS OrdersCount,
               SUM(CASE WHEN o.Status IN (N'Paid', N'Packed', N'Shipped', N'Delivered') THEN o.Total ELSE 0 END) AS TotalSpent,
               MAX(o.CreatedAt) AS LastOrderAt
        FROM dbo.Orders AS o
        GROUP BY o.UserId
    ) AS s ON s.UserId = u.Id
    WHERE u.Role = N'Customer'
      AND (@Status IS NULL
           OR (@Status = N'blocked' AND u.IsBlocked = 1)
           OR (@Status = N'active' AND u.IsBlocked = 0))
      AND (@Query IS NULL
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR u.Name LIKE N'%' + @Query + N'%'
           OR u.Email LIKE N'%' + @Query + N'%')
    ORDER BY
        CASE WHEN @Sort = N'orders'     THEN ISNULL(s.OrdersCount, 0) END DESC,
        CASE WHEN @Sort = N'spent'      THEN ISNULL(s.TotalSpent, 0) END DESC,
        CASE WHEN @Sort = N'last_order' THEN s.LastOrderAt END DESC,
        u.CreatedAt DESC,
        u.Id DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO