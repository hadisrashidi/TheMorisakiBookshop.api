USE MorisakiBookshop;
GO

-- 0012_users_name.sql
-- Adds dbo.Users.Name (shown in the UI: "<name> عزیز خوش آمدید") and the procedures that read/write it.
-- Safe to run more than once.

IF COL_LENGTH(N'dbo.Users', N'Name') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD Name NVARCHAR(100) NULL;
END
GO

-- The three read procedures now also return Name.
CREATE OR ALTER PROCEDURE dbo.Users_GetOrCreateByMobile
    @Mobile NVARCHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Mobile = @Mobile)
    BEGIN
        INSERT INTO dbo.Users (Mobile) VALUES (@Mobile);
    END

    SELECT Id, Mobile, Email, PasswordHash, Name, Role
    FROM dbo.Users
    WHERE Mobile = @Mobile;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Role
    FROM dbo.Users
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Role
    FROM dbo.Users
    WHERE Email = @Email;
END
GO

-- Returns AffectedRows (0 = no such user).
CREATE OR ALTER PROCEDURE dbo.Users_SetName
    @Id   INT,
    @Name NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users SET Name = @Name WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
