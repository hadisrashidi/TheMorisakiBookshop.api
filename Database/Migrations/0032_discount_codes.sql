USE MorisakiBookshop;
GO

-- 0032_discount_codes.sql
-- Discount codes: dbo.DiscountCodes (the codes), dbo.DiscountCodeUses (who used which code on which order),
-- Orders.DiscountCode + Orders.DiscountAmount (copied into the order, like the address), and the rules in SQL:
--   dbo.DiscountCodes_Check (is the code usable for this user and this price of books? how much does it take off?)
--   dbo.Orders_Place (redefined: optional @DiscountCode, checked again inside the order transaction)
--   dbo.DiscountCodes_GetAll / dbo.DiscountCodes_Save (for the admin API)
--   dbo.Orders_GetByUserId / dbo.Orders_GetById (redefined: also answer DiscountCode and DiscountAmount).
-- Rules: a code is either a PERCENT (with an optional maximum amount) or a FIXED amount (toman); it can have a minimum
-- price of the books, a start and an end time, a total usage limit and a limit per customer. Uses of CANCELLED orders do
-- not count (a cancelled order gives its use back). The discount takes off the price of the BOOKS only; shipping is
-- free from its FreeAbove by the price of the books BEFORE the discount.
-- Needs 0029. Safe to run more than once.

IF OBJECT_ID(N'dbo.DiscountCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DiscountCodes
    (
        Id           INT            IDENTITY(1,1) NOT NULL,
        Code         NVARCHAR(50)   NOT NULL,                  -- stored in capital letters
        Type         NVARCHAR(10)   NOT NULL,                  -- Percent | Fixed
        Value        DECIMAL(18,0)  NOT NULL,                  -- percent (1-100) or toman
        MaxDiscount  DECIMAL(18,0)  NULL,                      -- cap of a Percent code, NULL = no cap
        MinSubtotal  DECIMAL(18,0)  NULL,                      -- minimum price of the books, NULL = none
        StartsAt     DATETIME2(0)   NULL,                      -- UTC, NULL = already started
        EndsAt       DATETIME2(0)   NULL,                      -- UTC, exclusive, NULL = never ends
        UsageLimit   INT            NULL,                      -- total uses, NULL = unlimited
        PerUserLimit INT            NULL,                      -- uses per customer, NULL = unlimited
        IsActive     BIT            NOT NULL CONSTRAINT DF_DiscountCodes_IsActive DEFAULT (1),
        Note         NVARCHAR(200)  NOT NULL CONSTRAINT DF_DiscountCodes_Note DEFAULT (N''),
        CreatedAt    DATETIME2(0)   NOT NULL CONSTRAINT DF_DiscountCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_DiscountCodes PRIMARY KEY (Id),
        CONSTRAINT CK_DiscountCodes_Type CHECK (Type IN (N'Percent', N'Fixed')),
        CONSTRAINT CK_DiscountCodes_Value CHECK (Value > 0 AND (Type = N'Fixed' OR Value <= 100))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_DiscountCodes_Code' AND object_id = OBJECT_ID(N'dbo.DiscountCodes'))
BEGIN
    CREATE UNIQUE INDEX UX_DiscountCodes_Code ON dbo.DiscountCodes (Code);
END
GO

IF OBJECT_ID(N'dbo.DiscountCodeUses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DiscountCodeUses
    (
        Id             INT           IDENTITY(1,1) NOT NULL,
        CodeId         INT           NOT NULL,
        UserId         INT           NOT NULL,
        OrderId        INT           NOT NULL,
        DiscountAmount DECIMAL(18,0) NOT NULL,
        UsedAt         DATETIME2(0)  NOT NULL CONSTRAINT DF_DiscountCodeUses_UsedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_DiscountCodeUses PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_DiscountCodeUses_DiscountCodes', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.DiscountCodeUses
        ADD CONSTRAINT FK_DiscountCodeUses_DiscountCodes FOREIGN KEY (CodeId) REFERENCES dbo.DiscountCodes (Id);
END
GO

IF OBJECT_ID(N'dbo.FK_DiscountCodeUses_Orders', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.DiscountCodeUses
        ADD CONSTRAINT FK_DiscountCodeUses_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DiscountCodeUses_CodeId' AND object_id = OBJECT_ID(N'dbo.DiscountCodeUses'))
BEGIN
    CREATE INDEX IX_DiscountCodeUses_CodeId ON dbo.DiscountCodeUses (CodeId, UserId);
END
GO

IF COL_LENGTH(N'dbo.Orders', N'DiscountCode') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD DiscountCode NVARCHAR(50) NULL;
END
GO

IF COL_LENGTH(N'dbo.Orders', N'DiscountAmount') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD DiscountAmount DECIMAL(18,0) NOT NULL CONSTRAINT DF_Orders_DiscountAmount DEFAULT (0);
END
GO

-- The ONE place that decides whether a code can be used. Answers one row: CodeId, Reason, DiscountAmount.
-- Reason = Ok | NotFound | Inactive | NotStarted | Expired | MinSubtotal | UsageLimit | UserLimit.
-- It only reads (no transaction), so Orders_Place can call it with INSERT ... EXEC.
CREATE OR ALTER PROCEDURE dbo.DiscountCodes_Check
    @Code     NVARCHAR(50),
    @UserId   INT,
    @Subtotal DECIMAL(18,0)   -- the price of the books
AS
BEGIN
    SET NOCOUNT ON;

    SET @Code = UPPER(LTRIM(RTRIM(ISNULL(@Code, N''))));

    DECLARE @Id INT, @Type NVARCHAR(10), @Value DECIMAL(18,0), @MaxDiscount DECIMAL(18,0), @MinSubtotal DECIMAL(18,0);
    DECLARE @StartsAt DATETIME2(0), @EndsAt DATETIME2(0), @UsageLimit INT, @PerUserLimit INT, @IsActive BIT;

    SELECT @Id = Id, @Type = Type, @Value = Value, @MaxDiscount = MaxDiscount, @MinSubtotal = MinSubtotal,
           @StartsAt = StartsAt, @EndsAt = EndsAt, @UsageLimit = UsageLimit, @PerUserLimit = PerUserLimit, @IsActive = IsActive
    FROM dbo.DiscountCodes
    WHERE Code = @Code;

    IF @Id IS NULL
    BEGIN
        SELECT 0 AS CodeId, N'NotFound' AS Reason, CAST(0 AS DECIMAL(18,0)) AS DiscountAmount;
        RETURN;
    END

    DECLARE @Reason NVARCHAR(30) = N'Ok';

    IF @IsActive = 0
    BEGIN
        SET @Reason = N'Inactive';
    END
    ELSE IF @StartsAt IS NOT NULL AND SYSUTCDATETIME() < @StartsAt
    BEGIN
        SET @Reason = N'NotStarted';
    END
    ELSE IF @EndsAt IS NOT NULL AND SYSUTCDATETIME() >= @EndsAt
    BEGIN
        SET @Reason = N'Expired';
    END
    ELSE IF @MinSubtotal IS NOT NULL AND @Subtotal < @MinSubtotal
    BEGIN
        SET @Reason = N'MinSubtotal';
    END
    ELSE IF @UsageLimit IS NOT NULL
         AND (SELECT COUNT(*) FROM dbo.DiscountCodeUses AS u INNER JOIN dbo.Orders AS o ON o.Id = u.OrderId
              WHERE u.CodeId = @Id AND o.Status <> N'Cancelled') >= @UsageLimit
    BEGIN
        SET @Reason = N'UsageLimit';
    END
    ELSE IF @PerUserLimit IS NOT NULL
         AND (SELECT COUNT(*) FROM dbo.DiscountCodeUses AS u INNER JOIN dbo.Orders AS o ON o.Id = u.OrderId
              WHERE u.CodeId = @Id AND u.UserId = @UserId AND o.Status <> N'Cancelled') >= @PerUserLimit
    BEGIN
        SET @Reason = N'UserLimit';
    END

    DECLARE @Amount DECIMAL(18,0) = 0;

    IF @Reason = N'Ok'
    BEGIN
        IF @Type = N'Percent'
        BEGIN
            SET @Amount = FLOOR(@Subtotal * @Value / 100);

            IF @MaxDiscount IS NOT NULL AND @Amount > @MaxDiscount
            BEGIN
                SET @Amount = @MaxDiscount;
            END
        END
        ELSE
        BEGIN
            SET @Amount = @Value;
        END

        -- Never more than the books cost.
        IF @Amount > @Subtotal
        BEGIN
            SET @Amount = @Subtotal;
        END
    END

    SELECT @Id AS CodeId, @Reason AS Reason, @Amount AS DiscountAmount;
END
GO

-- For the admin API: every code with how many (not cancelled) orders used it and how much it took off in total.
CREATE OR ALTER PROCEDURE dbo.DiscountCodes_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.Id, c.Code, c.Type, c.Value, c.MaxDiscount, c.MinSubtotal, c.StartsAt, c.EndsAt,
           c.UsageLimit, c.PerUserLimit, c.IsActive, c.Note,
           (SELECT COUNT(*) FROM dbo.DiscountCodeUses AS u INNER JOIN dbo.Orders AS o ON o.Id = u.OrderId
            WHERE u.CodeId = c.Id AND o.Status <> N'Cancelled') AS UsesCount,
           ISNULL((SELECT SUM(u.DiscountAmount) FROM dbo.DiscountCodeUses AS u INNER JOIN dbo.Orders AS o ON o.Id = u.OrderId
                   WHERE u.CodeId = c.Id AND o.Status <> N'Cancelled'), 0) AS TotalDiscount
    FROM dbo.DiscountCodes AS c
    ORDER BY c.IsActive DESC, c.Id DESC;
END
GO

-- For the admin API: @Id = 0 creates a code, otherwise it changes that one. Answers the Id:
-- 0 = no code with that Id, -1 = another code already has this text.
CREATE OR ALTER PROCEDURE dbo.DiscountCodes_Save
    @Id           INT,
    @Code         NVARCHAR(50),
    @Type         NVARCHAR(10),
    @Value        DECIMAL(18,0),
    @MaxDiscount  DECIMAL(18,0) = NULL,
    @MinSubtotal  DECIMAL(18,0) = NULL,
    @StartsAt     DATETIME2(0)  = NULL,
    @EndsAt       DATETIME2(0)  = NULL,
    @UsageLimit   INT           = NULL,
    @PerUserLimit INT           = NULL,
    @IsActive     BIT,
    @Note         NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Code = UPPER(LTRIM(RTRIM(@Code)));

    IF EXISTS (SELECT 1 FROM dbo.DiscountCodes WHERE Code = @Code AND Id <> @Id)
    BEGIN
        SELECT -1 AS Id;
        RETURN;
    END

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.DiscountCodes (Code, Type, Value, MaxDiscount, MinSubtotal, StartsAt, EndsAt, UsageLimit, PerUserLimit, IsActive, Note)
        VALUES (@Code, @Type, @Value, @MaxDiscount, @MinSubtotal, @StartsAt, @EndsAt, @UsageLimit, @PerUserLimit, @IsActive, @Note);

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
        RETURN;
    END

    UPDATE dbo.DiscountCodes
    SET Code = @Code, Type = @Type, Value = @Value, MaxDiscount = @MaxDiscount, MinSubtotal = @MinSubtotal,
        StartsAt = @StartsAt, EndsAt = @EndsAt, UsageLimit = @UsageLimit, PerUserLimit = @PerUserLimit,
        IsActive = @IsActive, Note = @Note
    WHERE Id = @Id;

    SELECT CASE WHEN @@ROWCOUNT > 0 THEN @Id ELSE 0 END AS Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Orders_Place
    @UserId           INT,
    @RecipientName    NVARCHAR(100),
    @RecipientMobile  NVARCHAR(11),
    @Address          NVARCHAR(500),
    @PostalCode       NVARCHAR(10),
    @ShippingMethodId INT,
    @City             NVARCHAR(100),
    @Lines            NVARCHAR(MAX),  -- JSON: [{"BookId":1,"Quantity":2}]
    @DiscountCode     NVARCHAR(50) = NULL   -- optional discount code
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- The same book sent twice becomes one line with the summed quantity.
    DECLARE @Wanted TABLE (BookId INT NOT NULL PRIMARY KEY, Quantity INT NOT NULL);

    INSERT INTO @Wanted (BookId, Quantity)
    SELECT BookId, SUM(Quantity)
    FROM OPENJSON(@Lines)
         WITH (BookId INT '$.BookId', Quantity INT '$.Quantity')
    GROUP BY BookId;

    IF NOT EXISTS (SELECT 1 FROM @Wanted) OR EXISTS (SELECT 1 FROM @Wanted WHERE Quantity <= 0)
    BEGIN
        SELECT 0 AS OrderId, N'EmptyOrder' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
        RETURN;
    END

    DECLARE @IsTehran BIT = CASE WHEN LTRIM(RTRIM(REPLACE(REPLACE(@City, N'ي', N'ی'), N'ك', N'ک'))) = N'تهران' THEN 1 ELSE 0 END;
    DECLARE @MethodName NVARCHAR(100);
    DECLARE @MethodPrice DECIMAL(18,0);
    DECLARE @MethodFreeAbove DECIMAL(18,0);

    SELECT @MethodName = Name, @MethodPrice = Price, @MethodFreeAbove = FreeAbove
    FROM dbo.ShippingMethods
    WHERE Id = @ShippingMethodId
      AND IsActive = 1
      AND (@IsTehran = 1 OR TehranOnly = 0);

    IF @MethodName IS NULL
    BEGIN
        SELECT 0 AS OrderId, N'ShippingMethodInvalid' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
        RETURN;
    END

    DECLARE @ShippingCost DECIMAL(18,0);
    DECLARE @OrderId INT;

    BEGIN TRANSACTION;

    -- One UPDATE takes the stock only of the books that exist, are shown and have enough stock.
    -- If a concurrent order took the last copy, this UPDATE simply skips that book (no negative stock).
    UPDATE b
    SET b.Stock = b.Stock - w.Quantity
    FROM dbo.Books AS b
    INNER JOIN @Wanted AS w ON w.BookId = b.Id
    WHERE b.IsActive = 1
      AND b.Stock >= w.Quantity;

    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @Wanted)
    BEGIN
        ROLLBACK TRANSACTION;   -- gives the stock back

        SELECT TOP (1)
            0 AS OrderId,
            CASE WHEN b.Id IS NULL OR b.IsActive = 0 THEN N'BookNotFound' ELSE N'NotEnoughStock' END AS Problem,
            w.BookId AS ProblemBookId,
            ISNULL(b.Title, N'') AS ProblemTitle
        FROM @Wanted AS w
        LEFT JOIN dbo.Books AS b ON b.Id = w.BookId
        WHERE b.Id IS NULL OR b.IsActive = 0 OR b.Stock < w.Quantity
        ORDER BY w.BookId;

        RETURN;
    END

    DECLARE @Subtotal DECIMAL(18,0);

    SELECT @Subtotal = SUM(b.Price * w.Quantity)
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    -- Shipping is free from FreeAbove by the price of the BOOKS (before the discount code).
    SET @ShippingCost = CASE WHEN @MethodFreeAbove IS NOT NULL AND @Subtotal >= @MethodFreeAbove THEN 0 ELSE @MethodPrice END;

    DECLARE @CodeText NVARCHAR(50) = NULLIF(UPPER(LTRIM(RTRIM(ISNULL(@DiscountCode, N'')))), N'');
    DECLARE @CodeId INT = NULL;
    DECLARE @DiscountAmount DECIMAL(18,0) = 0;

    IF @CodeText IS NOT NULL
    BEGIN
        -- Locks the code row: two orders at the same moment cannot both take its last use.
        SELECT @CodeId = Id FROM dbo.DiscountCodes WITH (UPDLOCK, HOLDLOCK) WHERE Code = @CodeText;

        DECLARE @Check TABLE (CodeId INT NOT NULL, Reason NVARCHAR(30) NOT NULL, DiscountAmount DECIMAL(18,0) NOT NULL);

        INSERT INTO @Check (CodeId, Reason, DiscountAmount)
        EXEC dbo.DiscountCodes_Check @Code = @CodeText, @UserId = @UserId, @Subtotal = @Subtotal;

        DECLARE @Reason NVARCHAR(30);

        SELECT @Reason = Reason, @CodeId = CodeId, @DiscountAmount = DiscountAmount FROM @Check;

        IF @Reason <> N'Ok'
        BEGIN
            ROLLBACK TRANSACTION;   -- gives the stock back

            SELECT 0 AS OrderId, N'DiscountInvalid' AS Problem, 0 AS ProblemBookId, @Reason AS ProblemTitle;
            RETURN;
        END
    END

    INSERT INTO dbo.Orders (UserId, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode, ShippingMethodName, DiscountCode, DiscountAmount)
    VALUES (@UserId, @Subtotal, @ShippingCost, @Subtotal - @DiscountAmount + @ShippingCost, @RecipientName, @RecipientMobile, @Address, @PostalCode, @MethodName, @CodeText, @DiscountAmount);

    SET @OrderId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.OrderStatusHistory (OrderId, Status) VALUES (@OrderId, N'PendingPayment');

    IF @CodeId IS NOT NULL
    BEGIN
        INSERT INTO dbo.DiscountCodeUses (CodeId, UserId, OrderId, DiscountAmount) VALUES (@CodeId, @UserId, @OrderId, @DiscountAmount);
    END

    INSERT INTO dbo.OrderLines (OrderId, BookId, Title, Image, UnitPrice, Quantity)
    SELECT @OrderId, b.Id, b.Title, b.Image, b.Price, w.Quantity
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    COMMIT TRANSACTION;

    SELECT @OrderId AS OrderId, N'' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
END
GO

CREATE OR ALTER PROCEDURE dbo.Orders_GetByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Status, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode, TrackingCode, CreatedAt,
           ISNULL(ShippingMethodName, N'') AS ShippingMethodName, ISNULL(DiscountCode, N'') AS DiscountCode, DiscountAmount
    FROM dbo.Orders
    WHERE UserId = @UserId
    ORDER BY CreatedAt DESC, Id DESC;

    SELECT l.OrderId, l.BookId, l.Title, l.Image, l.UnitPrice, l.Quantity
    FROM dbo.OrderLines AS l
    INNER JOIN dbo.Orders AS o ON o.Id = l.OrderId
    WHERE o.UserId = @UserId
    ORDER BY l.OrderId, l.Id;

    SELECT h.OrderId, h.Status, h.ChangedAt
    FROM dbo.OrderStatusHistory AS h
    INNER JOIN dbo.Orders AS o ON o.Id = h.OrderId
    WHERE o.UserId = @UserId
    ORDER BY h.OrderId, h.Id;
END
GO

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
        u.Mobile AS UserMobile, u.Name AS UserName, u.Email AS UserEmail
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
