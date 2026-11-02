USE MorisakiBookshop;
GO

-- 0031_reviews_admin_search.sql
-- dbo.Reviews_Search: the reviews list of the admin panel (paged, newest first) with the book title and,
-- for reviews written by a logged-in user, the account's mobile number. Deleting uses dbo.Reviews_Delete (0024).
-- Needs 0002 + 0024. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Reviews_Search
    @Query    NVARCHAR(100) = NULL,   -- part of the review text, the reviewer name or the book title
    @Rating   INT           = NULL,   -- 1 to 5, NULL = all
    @Page     INT           = 1,
    @PageSize INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1
    BEGIN
        SET @Page = 1;
    END

    IF @PageSize < 1
    BEGIN
        SET @PageSize = 1;
    END

    IF @PageSize > 50
    BEGIN
        SET @PageSize = 50;
    END

    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');

    -- LIKE treats [ % _ as wildcards; wrap them so they are searched as plain characters.
    SET @Query = REPLACE(REPLACE(REPLACE(@Query, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]');

    -- Result set 1: totals for the pager (values actually used).
    SELECT COUNT(*) AS TotalCount, @Page AS Page, @PageSize AS PageSize
    FROM dbo.Reviews AS r
    INNER JOIN dbo.Books AS b ON b.Id = r.BookId
    WHERE (@Rating IS NULL OR r.Rating = @Rating)
      AND (@Query IS NULL
           OR r.Text LIKE N'%' + @Query + N'%'
           OR r.ReviewerName LIKE N'%' + @Query + N'%'
           OR b.Title LIKE N'%' + @Query + N'%');

    -- Result set 2: the requested page, newest first.
    SELECT r.Id, r.BookId, b.Title AS BookTitle, r.ReviewerName, r.Rating, r.Text, r.Date,
           u.Mobile AS UserMobile
    FROM dbo.Reviews AS r
    INNER JOIN dbo.Books AS b ON b.Id = r.BookId
    LEFT JOIN dbo.Users AS u ON u.Id = r.UserId
    WHERE (@Rating IS NULL OR r.Rating = @Rating)
      AND (@Query IS NULL
           OR r.Text LIKE N'%' + @Query + N'%'
           OR r.ReviewerName LIKE N'%' + @Query + N'%'
           OR b.Title LIKE N'%' + @Query + N'%')
    ORDER BY r.Id DESC
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO
