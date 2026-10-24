USE MorisakiBookshop;
GO

-- 0017_orders_admin_procedures.sql
-- Read procedures for the admin panel (admin API): dbo.Orders_Search (paged list with filters) and dbo.Orders_GetById (one order with its lines).
-- Run after 0016. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Orders_Search
    @Query    NVARCHAR(100) = NULL,   -- order number, recipient name, recipient mobile or account mobile
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
           OR u.Mobile LIKE N'%' + @Query + N'%');

    -- Result set 2: the requested page, newest first.
    SELECT
        o.Id,
        o.Status,
        o.Total,
        o.RecipientName,
        o.RecipientMobile,
        o.CreatedAt,
        ISNULL((SELECT SUM(l.Quantity) FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id), 0) AS ItemsCount
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE (@Status IS NULL OR o.Status = @Status)
      AND (@Query IS NULL
           OR o.Id = @OrderNumber
           OR o.RecipientName LIKE N'%' + @Query + N'%'
           OR o.RecipientMobile LIKE N'%' + @Query + N'%'
           OR u.Mobile LIKE N'%' + @Query + N'%')
    ORDER BY o.CreatedAt DESC, o.Id DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

CREATE OR ALTER PROCEDURE dbo.Orders_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: the order (no row = not found) and who placed it.
    SELECT
        o.Id, o.Status, o.Subtotal, o.ShippingCost, o.Total,
        o.RecipientName, o.RecipientMobile, o.Address, o.PostalCode, o.TrackingCode, o.CreatedAt,
        u.Mobile AS UserMobile, u.Name AS UserName, u.Email AS UserEmail
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE o.Id = @Id;

    -- Result set 2: the lines, with the data copied at purchase time.
    SELECT OrderId, BookId, Title, Image, UnitPrice, Quantity
    FROM dbo.OrderLines
    WHERE OrderId = @Id
    ORDER BY Id;
END
GO
