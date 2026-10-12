-- 0005_book_specs_procedures.sql
-- Creates the read procedures of dbo.BookSpecs. Specs are written by dbo.Books_Insert / dbo.Books_Update.
-- Run against MorisakiBookshop. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.BookSpecs_GetByBookId
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT BookId, Label, Value
    FROM dbo.BookSpecs
    WHERE BookId = @BookId
    ORDER BY SortOrder;
END
GO

-- For lists of books: one call for all specs instead of one call per book.
-- @BookIds is comma-separated text, e.g. N'1,2,3'.
CREATE OR ALTER PROCEDURE dbo.BookSpecs_GetByBookIds
    @BookIds NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT BookId, Label, Value
    FROM dbo.BookSpecs
    WHERE BookId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@BookIds, N','))
    ORDER BY BookId, SortOrder;
END
GO
