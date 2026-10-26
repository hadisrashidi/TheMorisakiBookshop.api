USE MorisakiBookshop;
GO

-- 0023_users_birthdate.sql
-- Adds Users.Birthdate (Jalali text like 1372/05/12, optional, same style as Reviews.Date).
-- The user read procedures now also return it; new dbo.Users_SetProfile saves name + birthdate together.
-- Safe to run more than once.

IF COL_LENGTH(N'dbo.Users', N'Birthdate') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD Birthdate NVARCHAR(10) NULL;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetOrCreateByMobile
    @Mobile NVARCHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Mobile = @Mobile)
    BEGIN
        INSERT INTO dbo.Users (Mobile) VALUES (@Mobile);
    END

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role
    FROM dbo.Users
    WHERE Mobile = @Mobile;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role
    FROM dbo.Users
    WHERE Id = @Id;
END
GO

-- Same as 0022 (lockout columns) plus Birthdate.
CREATE OR ALTER PROCEDURE dbo.Users_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Birthdate, Role,
           FailedLoginCount,
           CASE WHEN LockedUntil > SYSUTCDATETIME()
                THEN CAST(CEILING(DATEDIFF(SECOND, SYSUTCDATETIME(), LockedUntil) / 60.0) AS INT)
                ELSE 0 END AS LockedMinutesLeft
    FROM dbo.Users
    WHERE Email = @Email;
END
GO

-- An empty @Birthdate clears it. Returns AffectedRows (0 = no such user).
CREATE OR ALTER PROCEDURE dbo.Users_SetProfile
    @Id        INT,
    @Name      NVARCHAR(100),
    @Birthdate NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET Name = @Name,
        Birthdate = NULLIF(@Birthdate, N'')
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
