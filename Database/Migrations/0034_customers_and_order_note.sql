USE MorisakiBookshop;
GO

-- 0034_customers_and_order_note.sql
-- Customers for the admin panel: dbo.Customers_Search (paged list with order count, money spent and last order) and
-- dbo.Customers_GetById (one customer with the same numbers + her orders). Also an internal note on every order:
-- Orders.AdminNote + dbo.Orders_SetNote; dbo.Orders_GetById (last defined in 0032) also answers AdminNote and UserId.
-- A "customer" is an account with the role Customer. "Orders" = orders that are not cancelled; "spent" = the total of
-- the orders that are Paid, Packed, Shipped or Delivered (same meaning of "sale" as in the reports).
-- Needs 0032. Safe to run more than once.

IF COL_LENGTH(N'dbo.Orders', N'AdminNote') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD AdminNote NVARCHAR(500) NULL;
END
GO

-- Answers AffectedRows (0 = no such order). An empty note clears it.
CREATE OR ALTER PROCEDURE dbo.Orders_SetNote
    @Id   INT,
    @Note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Orders
    SET AdminNote = NULLIF(LTRIM(RTRIM(@Note)), N'')
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- Result set 1: totals for the pager (values actually used). Result set 2: the requested page.
CREATE OR ALTER PROCEDURE dbo.Customers_Search
    @Query    NVARCHAR(100) = NULL,   -- part of the name, the mobile number or the e-mail
    @Sort     NVARCHAR(20)  = NULL,   -- 'newest' (default) | 'orders' | 'spent' | 'last_order'
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

    -- LIKE treats [ % _ as wildcards; wrap them so they are searched as plain characters.
    SET @Query = REPLACE(REPLACE(REPLACE(@Query, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]');

    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize
    FROM dbo.Users AS u
    WHERE u.Role = N'Customer'
      AND (@Query IS NULL
           OR u.Mobile LIKE N'%' + @Query + N'%'
           OR u.Name LIKE N'%' + @Query + N'%'
           OR u.Email LIKE N'%' + @Query + N'%');

    SELECT u.Id, u.Name, u.Mobile, u.Email, u.CreatedAt,
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

-- Result set 1: the customer with her numbers (no row = not found). Result set 2: her orders, newest first.
CREATE OR ALTER PROCEDURE dbo.Customers_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.Id, u.Name, u.Mobile, u.Email, u.Birthdate, u.CreatedAt,
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
    WHERE u.Id = @Id AND u.Role = N'Customer';

    SELECT o.Id, o.Status, o.Total, o.CreatedAt,
           ISNULL((SELECT SUM(l.Quantity) FROM dbo.OrderLines AS l WHERE l.OrderId = o.Id), 0) AS ItemsCount
    FROM dbo.Orders AS o
    WHERE o.UserId = @Id
    ORDER BY o.CreatedAt DESC, o.Id DESC;
END
GO

-- Same as 0032 plus the internal note and the id of the customer account.
CREATE OR ALTER PROCEDURE dbo.Orders_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.Id, o.Status, o.Subtotal, o.ShippingCost, o.Total,
        o.RecipientName, o.RecipientMobile, o.Address, o.PostalCode, o.TrackingCode, o.CreatedAt,
        ISNULL(o.ShippingMethodName, N'') AS ShippingMethodName,
        ISNULL(o.DiscountCode, N'') AS DiscountCode, o.DiscountAmount,
        ISNULL(o.AdminNote, N'') AS AdminNote,
        u.Id AS UserId, u.Mobile AS UserMobile, u.Name AS UserName, u.Email AS UserEmail
    FROM dbo.Orders AS o
    INNER JOIN dbo.Users AS u ON u.Id = o.UserId
    WHERE o.Id = @Id;

    SELECT OrderId, BookId, Title, Image, UnitPrice, Quantity
    FROM dbo.OrderLines
    WHERE OrderId = @Id
    ORDER BY Id;

    SELECT OrderId, Status, ChangedAt
    FROM dbo.OrderStatusHistory
    WHERE OrderId = @Id
    ORDER BY Id;
END
GO
