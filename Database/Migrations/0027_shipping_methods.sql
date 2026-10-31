USE MorisakiBookshop;
GO

-- 0027_shipping_methods.sql
-- Shipping methods with a price: dbo.ShippingMethods, Orders.ShippingMethodName (a copy, like the other order data),
-- procedures for the shop (ShippingMethods_GetActive) and the admin API (GetAll / Save / SetActive),
-- and a new dbo.Orders_Place that needs a shipping method and fills Orders.ShippingCost from it.
-- Also dbo.Orders_GetByUserId and dbo.Orders_GetById now return ShippingMethodName.
-- The three seeded methods are PLACEHOLDERS (prices and texts): she changes them in the admin panel.
-- Needs 0016 + 0017. Safe to run more than once.

IF OBJECT_ID(N'dbo.ShippingMethods', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShippingMethods
    (
        Id           INT            IDENTITY(1,1) NOT NULL,
        Name         NVARCHAR(100)  NOT NULL,
        Price        DECIMAL(18,0)  NOT NULL,                 -- toman
        FreeAbove    DECIMAL(18,0)  NULL,                     -- NULL = never free; otherwise free when the books cost at least this
        DeliveryText NVARCHAR(300)  NOT NULL CONSTRAINT DF_ShippingMethods_DeliveryText DEFAULT (N''),
        TehranOnly   BIT            NOT NULL CONSTRAINT DF_ShippingMethods_TehranOnly DEFAULT (0),
        IsActive     BIT            NOT NULL CONSTRAINT DF_ShippingMethods_IsActive DEFAULT (1),
        SortOrder    INT            NOT NULL CONSTRAINT DF_ShippingMethods_SortOrder DEFAULT (0),
        CONSTRAINT PK_ShippingMethods PRIMARY KEY (Id),
        CONSTRAINT CK_ShippingMethods_Price CHECK (Price >= 0)
    );
END
GO

IF COL_LENGTH(N'dbo.Orders', N'ShippingMethodName') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD ShippingMethodName NVARCHAR(100) NULL;
END
GO

-- Placeholder rows, only when the table is empty (so a re-run never brings back deleted ones).
IF NOT EXISTS (SELECT 1 FROM dbo.ShippingMethods)
BEGIN
    INSERT INTO dbo.ShippingMethods (Name, Price, FreeAbove, DeliveryText, TehranOnly, IsActive, SortOrder)
    VALUES
        (N'پست پیشتاز', 80000, 2000000, N'ارسال به سراسر کشور؛ تحویل معمولاً ۲ تا ۵ روز کاری پس از ارسال. سفارش‌های ثبت‌شده تا ساعت ۱۲ ظهر در همان روز کاری پردازش می‌شوند.', 0, 1, 1),
        (N'پیک تهران', 60000, 2000000, N'فقط تهران؛ تحویل ۱ تا ۲ روز کاری، دم در ساختمان.', 1, 1, 2),
        (N'دریافت حضوری', 0, NULL, N'تحویل در محل فروشگاه در ساعات کاری (آدرس را در صفحه تماس ببینید).', 1, 0, 3);
END
GO

-- Methods the customer can pick. @Subtotal = price of the books: Cost is 0 when the method is free at that amount
-- (NULL = show the normal price). @City = the city of the address: Tehran = all methods, another city = the Tehran-only
-- methods are left out, NULL = show everything (the shipping information page). Arabic ي / ك are read as Persian ی / ک.
CREATE OR ALTER PROCEDURE dbo.ShippingMethods_GetActive
    @Subtotal DECIMAL(18,0) = NULL,
    @City     NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsTehran BIT = NULL;

    IF @City IS NOT NULL
    BEGIN
        SET @IsTehran = CASE WHEN LTRIM(RTRIM(REPLACE(REPLACE(@City, N'ي', N'ی'), N'ك', N'ک'))) = N'تهران' THEN 1 ELSE 0 END;
    END

    SELECT Id, Name, Price, FreeAbove, DeliveryText, TehranOnly,
           CASE WHEN FreeAbove IS NOT NULL AND @Subtotal IS NOT NULL AND @Subtotal >= FreeAbove THEN CAST(0 AS DECIMAL(18,0)) ELSE Price END AS Cost
    FROM dbo.ShippingMethods
    WHERE IsActive = 1
      AND (@IsTehran IS NULL OR @IsTehran = 1 OR TehranOnly = 0)
    ORDER BY SortOrder, Id;
END
GO

-- For the admin API: every method, active or not.
CREATE OR ALTER PROCEDURE dbo.ShippingMethods_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Price, FreeAbove, DeliveryText, TehranOnly, IsActive, SortOrder
    FROM dbo.ShippingMethods
    ORDER BY SortOrder, Id;
END
GO

-- For the admin API: @Id = 0 creates a method, otherwise it changes that one. Answers the Id (0 = not found).
CREATE OR ALTER PROCEDURE dbo.ShippingMethods_Save
    @Id           INT,
    @Name         NVARCHAR(100),
    @Price        DECIMAL(18,0),
    @FreeAbove    DECIMAL(18,0) = NULL,
    @DeliveryText NVARCHAR(300),
    @TehranOnly   BIT,
    @IsActive     BIT,
    @SortOrder    INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id = 0
    BEGIN
        INSERT INTO dbo.ShippingMethods (Name, Price, FreeAbove, DeliveryText, TehranOnly, IsActive, SortOrder)
        VALUES (@Name, @Price, @FreeAbove, @DeliveryText, @TehranOnly, @IsActive, @SortOrder);

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
        RETURN;
    END

    UPDATE dbo.ShippingMethods
    SET Name = @Name,
        Price = @Price,
        FreeAbove = @FreeAbove,
        DeliveryText = @DeliveryText,
        TehranOnly = @TehranOnly,
        IsActive = @IsActive,
        SortOrder = @SortOrder
    WHERE Id = @Id;

    SELECT CASE WHEN @@ROWCOUNT > 0 THEN @Id ELSE 0 END AS Id;
END
GO

-- Same as 0016 plus: needs @ShippingMethodId (an active method that fits the city) and fills ShippingCost from it.
-- New Problem codes: ShippingMethodInvalid. The price is worked out here from the database prices, never from the browser.
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

    INSERT INTO dbo.OrderLines (OrderId, BookId, Title, Image, UnitPrice, Quantity)
    SELECT @OrderId, b.Id, b.Title, b.Image, b.Price, w.Quantity
    FROM @Wanted AS w
    INNER JOIN dbo.Books AS b ON b.Id = w.BookId;

    COMMIT TRANSACTION;

    SELECT @OrderId AS OrderId, N'' AS Problem, 0 AS ProblemBookId, N'' AS ProblemTitle;
END
GO

-- Same as 0016 plus ShippingMethodName.
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
END
GO

-- Same as 0017 plus ShippingMethodName.
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
END
GO
