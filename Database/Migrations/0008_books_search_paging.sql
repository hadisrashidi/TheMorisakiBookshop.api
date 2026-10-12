USE MorisakiBookshop;
GO

-- Books_Search now filters by author and price range and returns one page.
-- Result set 1: TotalCount (all matching books) + the Page and PageSize actually used. Result set 2: the books of the requested page.
CREATE OR ALTER PROCEDURE dbo.Books_Search
    @Query       NVARCHAR(200) = NULL,
    @Genres      NVARCHAR(MAX) = NULL,
    @Languages   NVARCHAR(MAX) = NULL,
    @AuthorId    INT           = NULL,
    @MinPrice    DECIMAL(18,0) = NULL,
    @MaxPrice    DECIMAL(18,0) = NULL,
    @InStockOnly BIT           = 0,
    @Sort        NVARCHAR(20)  = NULL,
    @Page        INT           = 1,
    @PageSize    INT           = 9
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
    ORDER BY
        CASE WHEN @Sort = N'price_asc'  THEN Price   END ASC,
        CASE WHEN @Sort = N'price_desc' THEN Price   END DESC,
        CASE WHEN @Sort = N'newest'     THEN AddedAt END DESC,
        Id;

    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize FROM @Matches;

    SELECT Books.Id, Books.Title, Books.AuthorId, Books.Price, Books.OldPrice, Books.Stock,
           CAST(CASE WHEN Books.Stock > 0 THEN 1 ELSE 0 END AS BIT) AS InStock,
           Books.Image, Books.Description, Books.Genre, Books.Language, Books.AddedAt
    FROM @Matches AS Matches
    INNER JOIN dbo.Books ON Books.Id = Matches.BookId
    WHERE Matches.Position > (@Page - 1) * @PageSize
      AND Matches.Position <= @Page * @PageSize
    ORDER BY Matches.Position;
END
GO
