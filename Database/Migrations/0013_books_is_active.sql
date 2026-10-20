USE MorisakiBookshop;
GO

-- 0013_books_is_active.sql
-- Books can be hidden instead of deleted: new column dbo.Books.IsActive (1 = shown in the shop).
-- Every shop procedure now returns active books only; the admin panel passes @IncludeInactive = 1.
-- New procedures: dbo.Books_SetStock, dbo.Books_SetActive. dbo.Books_Delete is dropped (hide instead, so old orders keep their book).
-- Safe to run more than once.

IF COL_LENGTH(N'dbo.Books', N'IsActive') IS NULL
BEGIN
    ALTER TABLE dbo.Books ADD IsActive BIT NOT NULL CONSTRAINT DF_Books_IsActive DEFAULT (1);
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE IsActive = 1
    ORDER BY Id;
END
GO

-- @IncludeInactive = 1 (admin only) also finds hidden books.
CREATE OR ALTER PROCEDURE dbo.Books_GetById
    @Id              INT,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Id = @Id
      AND (@IncludeInactive = 1 OR IsActive = 1);
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_GetNewest
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE IsActive = 1
    ORDER BY AddedAt DESC, Id;
END
GO

-- In-stock books only. Discounted ones first (biggest discount first), then the rest so the section is never empty.
CREATE OR ALTER PROCEDURE dbo.Books_GetFeatured
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Stock > 0
      AND IsActive = 1
    ORDER BY
        CASE WHEN OldPrice IS NOT NULL THEN 0 ELSE 1 END,
        CASE WHEN OldPrice IS NOT NULL THEN OldPrice - Price ELSE 0 END DESC,
        Id;
END
GO

-- Same author first. Only when the author has no other book, other authors' books are returned.
-- Unknown @Id returns no rows.
CREATE OR ALTER PROCEDURE dbo.Books_GetRelated
    @Id    INT,
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuthorId INT = (SELECT AuthorId FROM dbo.Books WHERE Id = @Id);

    IF EXISTS (SELECT 1 FROM dbo.Books WHERE Id <> @Id AND AuthorId = @AuthorId AND IsActive = 1)
    BEGIN
        SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
               CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
               IsActive, Image, Description, Genre, Language, AddedAt
        FROM dbo.Books
        WHERE Id <> @Id AND AuthorId = @AuthorId AND IsActive = 1
        ORDER BY Id;
    END
    ELSE
    BEGIN
        SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
               CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
               IsActive, Image, Description, Genre, Language, AddedAt
        FROM dbo.Books
        WHERE Id <> @Id AND AuthorId <> @AuthorId AND IsActive = 1
        ORDER BY Id;
    END
END
GO

-- Always other authors' books; the same genre comes first, then the rest.
-- Unknown @Id returns no rows.
CREATE OR ALTER PROCEDURE dbo.Books_GetSimilar
    @Id    INT,
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuthorId INT           = (SELECT AuthorId FROM dbo.Books WHERE Id = @Id);
    DECLARE @Genre    NVARCHAR(50)  = (SELECT Genre    FROM dbo.Books WHERE Id = @Id);

    SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Id <> @Id AND AuthorId <> @AuthorId AND IsActive = 1
    ORDER BY
        CASE WHEN Genre = @Genre AND @Genre <> N'' THEN 0 ELSE 1 END,
        Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_GetByAuthor
    @AuthorId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           IsActive, Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE AuthorId = @AuthorId
      AND IsActive = 1
    ORDER BY Id;
END
GO

-- Same as 0008, plus @IncludeInactive (1 = admin list, also shows hidden books).
-- Result set 1: TotalCount (all matching books) + the Page and PageSize actually used. Result set 2: the books of the requested page.
CREATE OR ALTER PROCEDURE dbo.Books_Search
    @Query           NVARCHAR(200) = NULL,
    @Genres          NVARCHAR(MAX) = NULL,
    @Languages       NVARCHAR(MAX) = NULL,
    @AuthorId        INT           = NULL,
    @MinPrice        DECIMAL(18,0) = NULL,
    @MaxPrice        DECIMAL(18,0) = NULL,
    @InStockOnly     BIT           = 0,
    @Sort            NVARCHAR(20)  = NULL,
    @Page            INT           = 1,
    @PageSize        INT           = 9,
    @IncludeInactive BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;

    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');

    -- LIKE treats [ % _ as wildcards; wrap them so they are searched as plain characters.
    SET @Query = REPLACE(REPLACE(REPLACE(@Query, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]');

    -- Keep paging values sane: page >= 1, 1..50 books per page.
    IF @Page < 1
    BEGIN
        SET @Page = 1;
    END

    IF @PageSize < 1
    BEGIN
        SET @PageSize = 9;
    END

    IF @PageSize > 50
    BEGIN
        SET @PageSize = 50;
    END

    -- Filter and sort once; Position (IDENTITY) follows the ORDER BY, so it is the row number.
    DECLARE @Matches TABLE (Position INT IDENTITY(1,1) PRIMARY KEY, BookId INT NOT NULL);

    INSERT INTO @Matches (BookId)
    SELECT Id
    FROM dbo.Books
    WHERE (@Query IS NULL
           OR Title LIKE N'%' + @Query + N'%'
           OR Genre LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.BookSpecs
                      WHERE BookSpecs.BookId = Books.Id AND BookSpecs.Value LIKE N'%' + @Query + N'%'))
      AND (@Genres IS NULL OR Genre IN (SELECT value FROM STRING_SPLIT(@Genres, N',')))
      AND (@Languages IS NULL OR Language IN (SELECT value FROM STRING_SPLIT(@Languages, N',')))
      AND (@AuthorId IS NULL OR AuthorId = @AuthorId)
      AND (@MinPrice IS NULL OR Price >= @MinPrice)
      AND (@MaxPrice IS NULL OR Price <= @MaxPrice)
      AND (@InStockOnly = 0 OR Stock > 0)
      AND (@IncludeInactive = 1 OR IsActive = 1)
    ORDER BY
        CASE WHEN @Sort = N'price_asc'  THEN Price   END ASC,
        CASE WHEN @Sort = N'price_desc' THEN Price   END DESC,
        CASE WHEN @Sort = N'newest'     THEN AddedAt END DESC,
        Id;

    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize FROM @Matches;

    SELECT Books.Id, Books.Title, Books.AuthorId, Books.Price, Books.OldPrice, Books.Stock,
           CAST(CASE WHEN Books.Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Books.IsActive, Books.Image, Books.Description, Books.Genre, Books.Language, Books.AddedAt
    FROM @Matches AS Matches
    INNER JOIN dbo.Books ON Books.Id = Matches.BookId
    WHERE Matches.Position > (@Page - 1) * @PageSize
      AND Matches.Position <= @Page * @PageSize
    ORDER BY Matches.Position;
END
GO

-- Values for the search filters (shop and admin forms): hidden books do not count.
-- Result set 1: MinPrice, MaxPrice. Result set 2: distinct genres. Result set 3: distinct languages.
CREATE OR ALTER PROCEDURE dbo.Books_GetFilters
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(MIN(Price), 0) AS MinPrice, ISNULL(MAX(Price), 0) AS MaxPrice
    FROM dbo.Books
    WHERE IsActive = 1;

    SELECT DISTINCT Genre
    FROM dbo.Books
    WHERE Genre <> N'' AND IsActive = 1
    ORDER BY Genre;

    SELECT DISTINCT Language
    FROM dbo.Books
    WHERE Language <> N'' AND IsActive = 1
    ORDER BY Language;
END
GO

-- Changes only the stock (quick edit in the admin list).
CREATE OR ALTER PROCEDURE dbo.Books_SetStock
    @Id    INT,
    @Stock INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Books
    SET Stock = @Stock
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO

-- Shows (1) or hides (0) a book in the shop. Nothing is deleted.
CREATE OR ALTER PROCEDURE dbo.Books_SetActive
    @Id       INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Books
    SET IsActive = @IsActive
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO

-- Books are hidden, not deleted: orders (phase 3) must keep pointing at their book.
DROP PROCEDURE IF EXISTS dbo.Books_Delete;
GO
