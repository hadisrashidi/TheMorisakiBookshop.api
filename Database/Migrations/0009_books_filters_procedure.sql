USE MorisakiBookshop;
GO

-- Values for the search filters, read from the data so the UI never needs hand-typed lists.
-- Result set 1: MinPrice, MaxPrice. Result set 2: distinct genres. Result set 3: distinct languages.
CREATE OR ALTER PROCEDURE dbo.Books_GetFilters
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(MIN(Price), 0) AS MinPrice, ISNULL(MAX(Price), 0) AS MaxPrice
    FROM dbo.Books;

    SELECT DISTINCT Genre
    FROM dbo.Books
    WHERE Genre <> N''
    ORDER BY Genre;

    SELECT DISTINCT Language
    FROM dbo.Books
    WHERE Language <> N''
    ORDER BY Language;
END
GO
