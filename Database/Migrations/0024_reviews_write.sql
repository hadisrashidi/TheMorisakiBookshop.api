USE MorisakiBookshop;
GO

-- 0024_reviews_write.sql
-- Lets logged-in users write a review: adds Reviews.UserId (NULL for the old seeded reviews),
-- one review per user per book, and the procedures Reviews_Save, Reviews_GetByUserAndBook, Reviews_Delete.
-- Safe to run more than once.

IF COL_LENGTH(N'dbo.Reviews', N'UserId') IS NULL
BEGIN
    ALTER TABLE dbo.Reviews ADD UserId INT NULL;
END
GO

-- A deleted user keeps the review text (the name is copied into the review).
IF OBJECT_ID(N'dbo.FK_Reviews_Users', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Reviews
        ADD CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (Id) ON DELETE SET NULL;
END
GO

-- One review per user per book; the old seeded reviews have no user and are not limited.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Reviews_UserId_BookId' AND object_id = OBJECT_ID(N'dbo.Reviews'))
BEGIN
    CREATE UNIQUE INDEX UX_Reviews_UserId_BookId ON dbo.Reviews (UserId, BookId) WHERE UserId IS NOT NULL;
END
GO

-- Creates the review of this user for this book, or replaces it when the user already wrote one.
-- The reviewer name is read from the account. AffectedRows 0 = the book does not exist or is hidden.
CREATE OR ALTER PROCEDURE dbo.Reviews_Save
    @UserId INT,
    @BookId INT,
    @Rating INT,
    @Text   NVARCHAR(2000),
    @Date   NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = @BookId AND IsActive = 1)
    BEGIN
        SELECT 0 AS AffectedRows;
        RETURN;
    END

    DECLARE @ReviewerName NVARCHAR(100);

    SELECT @ReviewerName = ISNULL(NULLIF(Name, N''), N'کاربر')
    FROM dbo.Users
    WHERE Id = @UserId;

    BEGIN TRANSACTION;

    -- UPDLOCK + HOLDLOCK: two clicks at the same moment cannot both insert.
    IF EXISTS (SELECT 1 FROM dbo.Reviews WITH (UPDLOCK, HOLDLOCK) WHERE UserId = @UserId AND BookId = @BookId)
    BEGIN
        UPDATE dbo.Reviews
        SET ReviewerName = @ReviewerName,
            Rating = @Rating,
            Text = @Text,
            Date = @Date
        WHERE UserId = @UserId AND BookId = @BookId;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.Reviews (BookId, ReviewerName, Rating, Text, Date, UserId)
        VALUES (@BookId, @ReviewerName, @Rating, @Text, @Date, @UserId);
    END

    COMMIT TRANSACTION;

    SELECT 1 AS AffectedRows;
END
GO

-- The review this user already wrote for this book (no row = none), to fill the edit form.
CREATE OR ALTER PROCEDURE dbo.Reviews_GetByUserAndBook
    @UserId INT,
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, BookId, ReviewerName, Rating, Text, Date
    FROM dbo.Reviews
    WHERE UserId = @UserId AND BookId = @BookId;
END
GO

-- For the admin API: removes any review by id. AffectedRows 0 = not found.
CREATE OR ALTER PROCEDURE dbo.Reviews_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.Reviews WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
