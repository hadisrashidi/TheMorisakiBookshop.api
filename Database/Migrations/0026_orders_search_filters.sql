USE MorisakiBookshop;
GO

-- 0026_orders_search_filters.sql
-- Advanced filters for the admin orders list. dbo.Orders_Search (last defined in 0018) gets: a date range,
-- a total (price) range and a sort order, and answers a THIRD result set: how many orders each status has
-- under the same filters (without the status filter), for the status tabs with counts.
-- Replaces the procedure; old calls keep working (new parameters are optional). Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Orders_Search
    @Query    NVARCHAR(100) = NULL,   -- order number, recipient name, recipient mobile, account mobile or a book title
    @Status   NVARCHAR(30)  = NULL,   -- NULL = all statuses
    @FromDate DATETIME2(0)  = NULL,   -- UTC, orders created at or after this time
    @ToDate   DATETIME2(0)  = NULL,   -- UTC, orders created BEFORE this time (the day after the last wanted day)
    @MinTotal DECIMAL(18,0) = NULL,
    @MaxTotal DECIMAL(18,0) = NULL,
    @Sort     NVARCHAR(20)  = NULL,   -- 'newest' (default) | 'oldest' | 'total_desc' | 'total_asc'
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
    SET @Status = NULLIF(@Status, N'');

    DECLARE @OrderNumber INT = TRY_CAST(@Query AS INT);

    -- Every filter EXCEPT the status is applied once here; the three answers below read from this table.
    DECLARE @Matches TABLE
    (
        OrderId   INT           NOT NULL PRIMARY KEY,
        Status    NVARCHAR(30)  NOT NULL,
        Total     DECIMAL(18,0) NOT NULL,
        CreatedAt DATETIME2(0)  NOT NULL
    );

    INSERT INTO @Matches (OrderId, Status, Total, CreatedAt)
    SELECT o.Id, o.Status, o.Total, o.CreatedAt
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE (@FromDate IS NULL OR o.CreatedAt >= @FromDate)
      AND (@ToDate IS NULL OR o.CreatedAt < @ToDate)
      AND (@MinTotal IS NULL OR o.Total >= @MinTotal)
      AND (@MaxTotal IS NULL OR o.Total <= @MaxTotal)
      AND (@Query IS NULL
           OR o.Id = @OrderNumber
           OR o.RecipientName LIKE N'%' + @Query + N'%'
           OR o.RecipientMobile LIKE N'%' + @Query + N'%'
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id AND l.Title LIKE N'%' + @Query + N'%'));

    -- Result set 1: totals for the pager (values actually used).
    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize
    FROM @Matches AS m
    WHERE @Status IS NULL OR m.Status = @Status;

    -- Result set 2: the requested page.
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
    FROM @Matches AS m
    INNER JOIN dbo.Orders AS o ON o.Id = m.OrderId
    WHERE @Status IS NULL OR m.Status = @Status
    ORDER BY
        CASE WHEN @Sort = N'total_desc' THEN m.Total END DESC,
        CASE WHEN @Sort = N'total_asc'  THEN m.Total END ASC,
        CASE WHEN @Sort = N'oldest'     THEN m.CreatedAt END ASC,
        m.CreatedAt DESC,
        m.OrderId DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;

    -- Result set 3: orders per status under the same filters (statuses with no order are missing).
    SELECT m.Status, COUNT(*) AS OrdersCount
    FROM @Matches AS m
    GROUP BY m.Status;
END
GO
