-- 0004_authors_procedures.sql
-- Creates the stored procedures of dbo.Authors: GetAll, GetById, GetSimilar.
-- Run against MorisakiBookshop. Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Authors_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Image, Bio, Genre
    FROM dbo.Authors
    ORDER BY Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Authors_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Image, Bio, Genre
    FROM dbo.Authors
    WHERE Id = @Id;
END
GO

-- Other authors; the ones with the same genre come first, then the rest, so the row is never half empty.
-- Unknown @Id returns no rows.
CREATE OR ALTER PROCEDURE dbo.Authors_GetSimilar
    @Id    INT,
    @Count INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Genre NVARCHAR(50) = (SELECT Genre FROM dbo.Authors WHERE Id = @Id);

    SELECT TOP (@Count) Id, Name, Image, Bio, Genre
    FROM dbo.Authors
    WHERE Id <> @Id
      AND EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = @Id)
    ORDER BY
        CASE WHEN Genre = @Genre AND @Genre <> N'' THEN 0 ELSE 1 END,
        Id;
END
GO
