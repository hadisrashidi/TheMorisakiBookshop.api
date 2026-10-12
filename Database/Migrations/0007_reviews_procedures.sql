-- 0007_reviews_procedures.sql
-- Creates the stored procedures of dbo.Reviews: GetByBookId, GetByAuthorId.
-- Run against MorisakiBookshop. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Reviews_GetByBookId
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, BookId, ReviewerName, Rating, Text, Date
    FROM dbo.Reviews
    WHERE BookId = @BookId
    ORDER BY Id;
END
GO

-- All reviews of all books of one author (the join replaces the "load books, then reviews" code in C#).
CREATE OR ALTER PROCEDURE dbo.Reviews_GetByAuthorId
    @AuthorId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Reviews.Id, Reviews.BookId, Reviews.ReviewerName, Reviews.Rating, Reviews.Text, Reviews.Date
    FROM dbo.Reviews
    INNER JOIN dbo.Books ON Books.Id = Reviews.BookId
    WHERE Books.AuthorId = @AuthorId
    ORDER BY Reviews.Id;
END
GO
