USE MorisakiBookshop;
GO

-- 0022_login_lockout.sql
-- Locks the email + password login of one account for 15 minutes after 5 wrong passwords in a row.
-- Changes: two columns on dbo.Users; dbo.Users_GetByEmail also returns FailedLoginCount and LockedMinutesLeft;
-- new dbo.Users_RegisterFailedLogin and dbo.Users_ClearFailedLogins; dbo.Users_ResetPassword also unlocks.
-- The SMS-code login is NOT affected, so the real owner can always get in.
-- Safe to run more than once.

IF COL_LENGTH(N'dbo.Users', N'FailedLoginCount') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_FailedLoginCount DEFAULT (0);
END
GO

IF COL_LENGTH(N'dbo.Users', N'LockedUntil') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD LockedUntil DATETIME2(0) NULL;
END
GO

-- LockedMinutesLeft is worked out here in SQL (not in C#), so the database clock is the only clock.
CREATE OR ALTER PROCEDURE dbo.Users_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Name, Role,
           FailedLoginCount,
           CASE WHEN LockedUntil > SYSUTCDATETIME()
                THEN CAST(CEILING(DATEDIFF(SECOND, SYSUTCDATETIME(), LockedUntil) / 60.0) AS INT)
                ELSE 0 END AS LockedMinutesLeft
    FROM dbo.Users
    WHERE Email = @Email;
END
GO

-- Called after a wrong password. The 5th wrong password in a row locks the account for 15 minutes
-- and starts the count again. Returns LockedMinutesLeft (0 = not locked yet).
CREATE OR ALTER PROCEDURE dbo.Users_RegisterFailedLogin
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxFailures INT = 5;
    DECLARE @LockMinutes INT = 15;

    -- One UPDATE does the counting, so two wrong passwords at the same moment are both counted.
    UPDATE dbo.Users
    SET FailedLoginCount = CASE WHEN FailedLoginCount + 1 >= @MaxFailures THEN 0 ELSE FailedLoginCount + 1 END,
        LockedUntil = CASE WHEN FailedLoginCount + 1 >= @MaxFailures
                           THEN DATEADD(MINUTE, @LockMinutes, SYSUTCDATETIME())
                           ELSE LockedUntil END
    WHERE Id = @Id;

    SELECT CASE WHEN LockedUntil > SYSUTCDATETIME() THEN @LockMinutes ELSE 0 END AS LockedMinutesLeft
    FROM dbo.Users
    WHERE Id = @Id;
END
GO

-- Called after a right password.
CREATE OR ALTER PROCEDURE dbo.Users_ClearFailedLogins
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE Id = @Id;
END
GO

-- Same as before (0011) plus: a reset by SMS code proves the owner, so the lock is lifted.
CREATE OR ALTER PROCEDURE dbo.Users_ResetPassword
    @Mobile       NVARCHAR(11),
    @PasswordHash NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET PasswordHash = @PasswordHash,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE Mobile = @Mobile AND PasswordHash IS NOT NULL;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
