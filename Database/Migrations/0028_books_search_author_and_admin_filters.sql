USE MorisakiBookshop;
GO

-- 0028_books_search_author_and_admin_filters.sql
-- dbo.Books_Search (last defined in 0013) gets:
--   * the search text ALSO matches the author's name (shop search box and admin list),
--   * @StockStatus (admin filter): 'in' = in stock, 'out' = out of stock, 'low' = 1 to 5 copies left,
--   * @Visibility (admin filter): 'active' = shown in the shop, 'hidden' = hidden (needs @IncludeInactive = 1),
--   * two more sort orders: 'stock_asc' (fewest copies first) and 'title'.
-- Old calls keep working (new parameters are optional). Safe to run more than once.

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
    @IncludeInactive BIT           = 0,
    @StockStatus     NVARCHAR(10)  = NULL,
    @Visibility      NVARCHAR(10)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');
    SET @StockStatus = NULLIF(@StockStatus, N'');
    SET @Visibility = NULLIF(@Visibility, N'');

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
    SELECT Books.Id
    FROM dbo.Books
    WHERE (@Query IS NULL
           OR Books.Title LIKE N'%' + @Query + N'%'
           OR Books.Genre LIKE N'%' + @Query + N'%'
           OR EXISTS (SELECT 1 FROM dbo.Authors
                      WHERE Authors.Id = Books.AuthorId AND Authors.Name LIKE N'%' + @Query + N'%')
           OR EXISTS (SELECT 1 FROM dbo.BookSpecs
                      WHERE BookSpecs.BookId = Books.Id AND BookSpecs.Value LIKE N'%' + @Query + N'%'))
      AND (@Genres IS NULL OR Books.Genre IN (SELECT value FROM STRING_SPLIT(@Genres, N',')))
      AND (@Languages IS NULL OR Books.Language IN (SELECT value FROM STRING_SPLIT(@Languages, N',')))
      AND (@AuthorId IS NULL OR Books.AuthorId = @AuthorId)
      AND (@MinPrice IS NULL OR Books.Price >= @MinPrice)
      AND (@MaxPrice IS NULL OR Books.Price <= @MaxPrice)
      AND (@InStockOnly = 0 OR Books.Stock > 0)
      AND (@StockStatus IS NULL
           OR (@StockStatus = N'in'  AND Books.Stock > 0)
           OR (@StockStatus = N'out' AND Books.Stock = 0)
           OR (@StockStatus = N'low' AND Books.Stock BETWEEN 1 AND 5))
      AND (@IncludeInactive = 1 OR Books.IsActive = 1)
      AND (@Visibility IS NULL
           OR (@Visibility = N'active' AND Books.IsActive = 1)
           OR (@Visibility = N'hidden' AND Books.IsActive = 0 AND @IncludeInactive = 1))
    ORDER BY
        CASE WHEN @Sort = N'price_asc'  THEN Books.Price   END ASC,
        CASE WHEN @Sort = N'price_desc' THEN Books.Price   END DESC,
        CASE WHEN @Sort = N'newest'     THEN Books.AddedAt END DESC,
        CASE WHEN @Sort = N'stock_asc'  THEN Books.Stock   END ASC,
        CASE WHEN @Sort = N'title'      THEN Books.Title   END ASC,
        Books.Id;

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
