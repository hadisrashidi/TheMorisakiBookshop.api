USE MorisakiBookshop;
GO

-- 0037_customer_note.sql
-- An internal note on every customer account (Users.AdminNote, max 500) for the admins only: the shop API never
-- sends it. dbo.Customers_SetNote saves it (customers only, never an admin account); dbo.Customers_GetById
-- (last defined in 0034) also answers AdminNote. Needs 0034. Safe to run more than once.

IF COL_LENGTH(N'dbo.Users', N'AdminNote') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD AdminNote NVARCHAR(500) NULL;
END
GO

-- Answers AffectedRows (0 = no such customer). An empty note clears it.
CREATE OR ALTER PROCEDURE dbo.Customers_SetNote
    @Id   INT,
    @Note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET AdminNote = NULLIF(LTRIM(RTRIM(@Note)), N'')
    WHERE Id = @Id AND Role = N'Customer';

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- Same as 0034 plus the internal note.
CREATE OR ALTER PROCEDURE dbo.Customers_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.Id, u.Name, u.Mobile, u.Email, u.Birthdate, u.CreatedAt,
           ISNULL(u.AdminNote, N'') AS AdminNote,
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
