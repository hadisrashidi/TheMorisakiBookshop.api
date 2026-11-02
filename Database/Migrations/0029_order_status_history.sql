USE MorisakiBookshop;
GO

-- 0029_order_status_history.sql
-- The history of every order: dbo.OrderStatusHistory (one row each time the status changes, with the time).
-- Used for the customer's order tracking timeline (shop) and the admin order page.
-- Changes: new table (+ one "PendingPayment" row for every existing order, at its creation time);
--   dbo.Orders_Place writes the first row; dbo.Orders_SetStatus writes a row at every change and gets the optional
--   @OnlyIfStatus (the move is refused unless the order is in that status right now);
--   new dbo.Orders_CancelMine (a customer cancels HER OWN order, only while it is PendingPayment);
--   dbo.Orders_GetByUserId and dbo.Orders_GetById answer the history as one more result set.
-- Needs 0019 + 0027. Safe to run more than once.

IF OBJECT_ID(N'dbo.OrderStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderStatusHistory
    (
        Id        INT           IDENTITY(1,1) NOT NULL,
        OrderId   INT           NOT NULL,
        Status    NVARCHAR(30)  NOT NULL,
        ChangedAt DATETIME2(0)  NOT NULL CONSTRAINT DF_OrderStatusHistory_ChangedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_OrderStatusHistory PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_OrderStatusHistory_Orders', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.OrderStatusHistory
        ADD CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders (Id) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderStatusHistory_OrderId' AND object_id = OBJECT_ID(N'dbo.OrderStatusHistory'))
BEGIN
    CREATE INDEX IX_OrderStatusHistory_OrderId ON dbo.OrderStatusHistory (OrderId);
END
GO

-- Older orders get their first row only (when the later changes happened was never recorded).
INSERT INTO dbo.OrderStatusHistory (OrderId, Status, ChangedAt)
SELECT o.Id, N'PendingPayment', o.CreatedAt
FROM dbo.Orders AS o
WHERE NOT EXISTS (SELECT 1 FROM dbo.OrderStatusHistory AS h WHERE h.OrderId = o.Id);
GO

-- Same moves as 0019 plus: a history row at every change, and @OnlyIfStatus (NULL = no extra condition).
CREATE OR ALTER PROCEDURE dbo.Orders_SetStatus
    @Id           INT,
    @Status       NVARCHAR(30),
    @TrackingCode NVARCHAR(50) = NULL,   -- NULL = leave the tracking code as it is
    @OnlyIfStatus NVARCHAR(30) = NULL    -- NULL = no extra condition
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Current NVARCHAR(30);

    BEGIN TRANSACTION;

    -- UPDLOCK: two clicks at the same time cannot both pass the check below.
    SELECT @Current = Status
    FROM dbo.Orders WITH (UPDLOCK, ROWLOCK)
    WHERE Id = @Id;

    IF @Current IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT N'NotFound' AS Result, N'' AS CurrentStatus;
        RETURN;
    END

    IF (@OnlyIfStatus IS NOT NULL AND @Current <> @OnlyIfStatus)
       OR NOT (   (@Current = N'PendingPayment' AND @Status IN (N'Paid', N'Cancelled'))
               OR (@Current = N'Paid'           AND @Status IN (N'Packed', N'Cancelled'))
               OR (@Current = N'Packed'         AND @Status IN (N'Shipped', N'Cancelled'))
               OR (@Current = N'Shipped'        AND @Status IN (N'Shipped', N'Delivered')))
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT N'InvalidTransition' AS Result, @Current AS CurrentStatus;
        RETURN;
    END

    UPDATE dbo.Orders
    SET Status = @Status,
        TrackingCode = CASE WHEN @TrackingCode IS NULL THEN TrackingCode ELSE LTRIM(RTRIM(@TrackingCode)) END
    WHERE Id = @Id;

    -- Shipped -> Shipped only corrects the tracking code: that is not a new step.
    IF @Status <> @Current
    BEGIN
        INSERT INTO dbo.OrderStatusHistory (OrderId, Status) VALUES (@Id, @Status);
    END

    IF @Status = N'Cancelled'
    BEGIN
        UPDATE b
        SET b.Stock = b.Stock + l.Quantity
        FROM dbo.Books AS b
        INNER JOIN dbo.OrderLines AS l ON l.BookId = b.Id
        WHERE l.OrderId = @Id;
    END

    COMMIT TRANSACTION;

    SELECT N'Ok' AS Result, @Status AS CurrentStatus;
END
GO

-- A customer cancels her OWN order, only while it is still waiting for payment (the stock goes back, see Orders_SetStatus).
-- Answers one row: Result = Ok | NotFound (no such order of this user) | InvalidTransition (not PendingPayment any more).
CREATE OR ALTER PROCEDURE dbo.Orders_CancelMine
    @UserId INT,
    @Id     INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE Id = @Id AND UserId = @UserId)
    BEGIN
        SELECT N'NotFound' AS Result, N'' AS CurrentStatus;
        RETURN;
    END

    EXEC dbo.Orders_SetStatus @Id = @Id, @Status = N'Cancelled', @OnlyIfStatus = N'PendingPayment';
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
    @Lines            NVARCHAR(MAX)   -- JSON: [{"BookId":1,"Quantity":2}]
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

    SET @ShippingCost = CASE WHEN @MethodFreeAbove IS NOT NULL AND @Subtotal >= @MethodFreeAbove THEN 0 ELSE @MethodPrice END;

    INSERT INTO dbo.Orders (UserId, Subtotal, ShippingCost, Total, RecipientName, RecipientMobile, Address, PostalCode, ShippingMethodName)
    VALUES (@UserId, @Subtotal, @ShippingCost, @Subtotal + @ShippingCost, @RecipientName, @RecipientMobile, @Address, @PostalCode, @MethodName);

    SET @OrderId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.OrderStatusHistory (OrderId, Status) VALUES (@OrderId, N'PendingPayment');

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
           ISNULL(ShippingMethodName, N'') AS ShippingMethodName
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
