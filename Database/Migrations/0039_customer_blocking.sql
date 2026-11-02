USE MorisakiBookshop;
GO

-- 0039_customer_blocking.sql
-- Blocking a customer. A blocked account cannot log in (any method) and its old login tokens stop working at once
-- (the API asks dbo.Users_IsBlocked on every request that carries a token). Her orders, addresses and reviews stay
-- as they are; the admin handles running orders by hand. Only accounts with the role Customer can be blocked.
--   Users.IsBlocked / BlockReason (admin-only text, max 300) / BlockedAt (UTC)
--   dbo.Customers_SetBlocked  - block (with a reason) or unblock
--   dbo.Users_IsBlocked       - one cheap check for the token validation
--   dbo.Users_GetOrCreateByMobile / Users_GetById / Users_GetByEmail - redefined (+ IsBlocked)
--   dbo.Customers_Search / Customers_GetById - redefined (+ IsBlocked, BlockReason, BlockedAt)
-- Needs 0037. Safe to run more than once.

IF COL_LENGTH(N'dbo.Users', N'IsBlocked') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD IsBlocked BIT NOT NULL CONSTRAINT DF_Users_IsBlocked DEFAULT (0);
END
GO

IF COL_LENGTH(N'dbo.Users', N'BlockReason') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD BlockReason NVARCHAR(300) NULL;
END
GO

IF COL_LENGTH(N'dbo.Users', N'BlockedAt') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD BlockedAt DATETIME2(0) NULL;
END
GO

-- Answers AffectedRows (0 = no such customer). Unblocking clears the reason and the time.
CREATE OR ALTER PROCEDURE dbo.Customers_SetBlocked
    @Id        INT,
    @IsBlocked BIT,
    @Reason    NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET IsBlocked = @IsBlocked,
        BlockReason = CASE WHEN @IsBlocked = 1 THEN NULLIF(LTRIM(RTRIM(@Reason)), N'') ELSE NULL END,
        BlockedAt = CASE WHEN @IsBlocked = 1 THEN SYSUTCDATETIME() ELSE NULL END
    WHERE Id = @Id AND Role = N'Customer';

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- One value: 1 = blocked. An unknown id answers 0 (the token rules decide about it).
CREATE OR ALTER PROCEDURE dbo.Users_IsBlocked
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CAST(ISNULL((SELECT IsBlocked FROM dbo.Users WHERE Id = @Id), 0) AS BIT) AS IsBlocked;
END
GO

-- Same as 0023 plus IsBlocked.
CREATE OR ALTER PROCEDURE dbo.Users_GetOrCreateByMobile
    @Mobile NVARCHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Mobile = @Mobile)
    BEGIN
        INSERT INTO dbo.Users (Mobile) VALUES (@Mobile);
    END

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role, IsBlocked
    FROM dbo.Users
    WHERE Mobile = @Mobile;
END
GO

-- Same as 0023 plus IsBlocked.
CREATE OR ALTER PROCEDURE dbo.Users_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role, IsBlocked
    FROM dbo.Users
    WHERE Id = @Id;
END
GO

-- Same as 0023 (lockout columns, Birthdate) plus IsBlocked.
CREATE OR ALTER PROCEDURE dbo.Users_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role, IsBlocked,
           FailedLoginCount,
           CASE WHEN LockedUntil > SYSUTCDATETIME()
                THEN CAST(CEILING(DATEDIFF(SECOND, SYSUTCDATETIME(), LockedUntil) / 60.0) AS INT)
                ELSE 0 END AS LockedMinutesLeft
    FROM dbo.Users
    WHERE Email = @Email;
END
GO

-- Same as 0034 plus IsBlocked in the page rows.
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
-- Same as 0037 plus IsBlocked, BlockReason and BlockedAt.
CREATE OR ALTER PROCEDURE dbo.Customers_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.Id, u.Name, u.Mobile, u.Email, u.Birthdate, u.CreatedAt,
           ISNULL(u.AdminNote, N'') AS AdminNote,
           u.IsBlocked, ISNULL(u.BlockReason, N'') AS BlockReason, u.BlockedAt,
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