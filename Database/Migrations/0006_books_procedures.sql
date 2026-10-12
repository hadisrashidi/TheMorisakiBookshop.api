-- 0006_books_procedures.sql
-- Creates the stored procedures of dbo.Books: GetAll, GetById, GetNewest, GetFeatured, GetRelated,
-- GetSimilar, GetByAuthor, Search, Insert, Update, Delete.
-- InStock is not a column: it is computed as Stock > 0 (see DECISIONS 2026-10-12, still to be confirmed).
-- Specs are not returned here: they come from dbo.BookSpecs_GetByBookId / dbo.BookSpecs_GetByBookIds.
-- Run against MorisakiBookshop. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Books_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    ORDER BY Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_GetNewest
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
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
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Stock > 0
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

    IF EXISTS (SELECT 1 FROM dbo.Books WHERE Id <> @Id AND AuthorId = @AuthorId)
    BEGIN
        SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
               CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
               Image, Description, Genre, Language, AddedAt
        FROM dbo.Books
        WHERE Id <> @Id AND AuthorId = @AuthorId
        ORDER BY Id;
    END
    ELSE
    BEGIN
        SELECT TOP (@Count) Id, Title, AuthorId, Price, OldPrice, Stock,
               CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
               Image, Description, Genre, Language, AddedAt
        FROM dbo.Books
        WHERE Id <> @Id AND AuthorId <> @AuthorId
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
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE Id <> @Id AND AuthorId <> @AuthorId
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
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE AuthorId = @AuthorId
    ORDER BY Id;
END
GO

-- Optional filters: NULL means "don't filter". Lists come as comma-separated text (N'رمان,شعر').
-- @Query matches the title, the genre or any spec value. @Sort: 'price_asc' | 'price_desc' | 'newest' | NULL (= by Id).
-- Paging, author / category / price-range filters come in task 8.
CREATE OR ALTER PROCEDURE dbo.Books_Search
    @Query       NVARCHAR(200) = NULL,
    @Genres      NVARCHAR(MAX) = NULL,
    @Languages   NVARCHAR(MAX) = NULL,
    @InStockOnly BIT           = 0,
    @Sort        NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');

    -- LIKE treats [ % _ as wildcards; wrap them so they are searched as plain characters.
    SET @Query = REPLACE(REPLACE(REPLACE(@Query, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]');

    SELECT Id, Title, AuthorId, Price, OldPrice, Stock,
           CAST(CASE WHEN Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Image, Description, Genre, Language, AddedAt
    FROM dbo.Books
    WHERE (@Query IS NULL
           OR Title LIKE N'%' + @Query + N'%'
           OR Genre LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.BookSpecs
                      WHERE BookSpecs.BookId = Books.Id AND BookSpecs.Value LIKE N'%' + @Query + N'%'))
      AND (@Genres IS NULL OR Genre IN (SELECT value FROM STRING_SPLIT(@Genres, N',')))
      AND (@Languages IS NULL OR Language IN (SELECT value FROM STRING_SPLIT(@Languages, N',')))
      AND (@InStockOnly = 0 OR Stock > 0)
    ORDER BY
        CASE WHEN @Sort = N'price_asc'  THEN Price   END ASC,
        CASE WHEN @Sort = N'price_desc' THEN Price   END DESC,
        CASE WHEN @Sort = N'newest'     THEN AddedAt END DESC,
        Id;
END
GO

-- @Specs is JSON text: [{"Label":"...","Value":"..."}, ...]. The book and its specs are saved together or not at all.
CREATE OR ALTER PROCEDURE dbo.Books_Insert
    @Title       NVARCHAR(200),
    @AuthorId    INT,
    @Price       DECIMAL(18,0),
    @OldPrice    DECIMAL(18,0) = NULL,
    @Stock       INT,
    @Image       NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Genre       NVARCHAR(50),
    @Language    NVARCHAR(50),
    @Specs       NVARCHAR(MAX) = N'[]'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NewId INT;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Books (Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language)
    VALUES (@Title, @AuthorId, @Price, @OldPrice, @Stock, @Image, @Description, @Genre, @Language);

    SET @NewId = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    SELECT @NewId,
           CAST(spec.[key] AS INT) + 1,
           JSON_VALUE(spec.value, '$.Label'),
           JSON_VALUE(spec.value, '$.Value')
    FROM OPENJSON(@Specs) AS spec;

    COMMIT TRANSACTION;

    SELECT @NewId AS Id;   -- the new Id
END
GO

-- Replaces the book's fields and ALL its specs. AddedAt never changes.
CREATE OR ALTER PROCEDURE dbo.Books_Update
    @Id          INT,
    @Title       NVARCHAR(200),
    @AuthorId    INT,
    @Price       DECIMAL(18,0),
    @OldPrice    DECIMAL(18,0) = NULL,
    @Stock       INT,
    @Image       NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Genre       NVARCHAR(50),
    @Language    NVARCHAR(50),
    @Specs       NVARCHAR(MAX) = N'[]'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AffectedRows INT;

    BEGIN TRANSACTION;

    UPDATE dbo.Books
    SET Title = @Title,
        AuthorId = @AuthorId,
        Price = @Price,
        OldPrice = @OldPrice,
        Stock = @Stock,
        Image = @Image,
        Description = @Description,
        Genre = @Genre,
        Language = @Language
    WHERE Id = @Id;

    SET @AffectedRows = @@ROWCOUNT;

    IF @AffectedRows > 0
    BEGIN
        DELETE FROM dbo.BookSpecs WHERE BookId = @Id;

        INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
        SELECT @Id,
               CAST(spec.[key] AS INT) + 1,
               JSON_VALUE(spec.value, '$.Label'),
               JSON_VALUE(spec.value, '$.Value')
        FROM OPENJSON(@Specs) AS spec;
    END

    COMMIT TRANSACTION;

    SELECT @AffectedRows AS AffectedRows;   -- 0 = not found
END
GO

-- Specs and reviews of the book are deleted with it (ON DELETE CASCADE).
CREATE OR ALTER PROCEDURE dbo.Books_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.Books WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO
