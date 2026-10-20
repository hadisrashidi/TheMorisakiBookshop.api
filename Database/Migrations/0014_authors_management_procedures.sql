USE MorisakiBookshop;
GO

-- 0014_authors_management_procedures.sql
-- Admin panel: dbo.Authors_Insert and dbo.Authors_Update.
-- Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Authors_Insert
    @Name  NVARCHAR(100),
    @Image NVARCHAR(200),
    @Bio   NVARCHAR(MAX),
    @Genre NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Authors (Name, Image, Bio, Genre)
    VALUES (@Name, @Image, @Bio, @Genre);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;   -- the new Id
END
GO

CREATE OR ALTER PROCEDURE dbo.Authors_Update
    @Id    INT,
    @Name  NVARCHAR(100),
    @Image NVARCHAR(200),
    @Bio   NVARCHAR(MAX),
    @Genre NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Authors
    SET Name = @Name,
        Image = @Image,
        Bio = @Bio,
        Genre = @Genre
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO
