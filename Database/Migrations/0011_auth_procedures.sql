USE MorisakiBookshop;
GO

-- 0011_auth_procedures.sql
-- Stored procedures for login: OTP codes (with resend and wrong-try limits) and users.
-- Safe to run more than once.

-- Stores a new code. Rules: at most 1 code per minute and 5 per hour for one mobile.
-- Returns Status: 'Ok' | 'TooSoon' | 'TooMany'.
CREATE OR ALTER PROCEDURE dbo.OtpCodes_Create
    @Mobile        NVARCHAR(11),
    @CodeHash      NVARCHAR(100),
    @ExpiryMinutes INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2(0) = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM dbo.OtpCodes WHERE Mobile = @Mobile AND CreatedAt > DATEADD(MINUTE, -1, @Now))
    BEGIN
        SELECT N'TooSoon' AS Status;
        RETURN;
    END

    IF (SELECT COUNT(*) FROM dbo.OtpCodes WHERE Mobile = @Mobile AND CreatedAt > DATEADD(HOUR, -1, @Now)) >= 5
    BEGIN
        SELECT N'TooMany' AS Status;
        RETURN;
    END

    INSERT INTO dbo.OtpCodes (Mobile, CodeHash, ExpiresAt, CreatedAt)
    VALUES (@Mobile, @CodeHash, DATEADD(MINUTE, @ExpiryMinutes, @Now), @Now);

    SELECT N'Ok' AS Status;
END
GO

-- Checks the newest unused code of this mobile. 5 wrong tries lock that code.
-- Returns Status: 'Ok' | 'Invalid' | 'Expired' | 'Locked'.
-- A right code is marked as used, so it works only once.
CREATE OR ALTER PROCEDURE dbo.OtpCodes_Verify
    @Mobile   NVARCHAR(11),
    @CodeHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @Id INT;
    DECLARE @StoredHash NVARCHAR(100);
    DECLARE @ExpiresAt DATETIME2(0);
    DECLARE @FailedAttempts INT;

    BEGIN TRANSACTION;

    SELECT TOP (1)
        @Id = Id,
        @StoredHash = CodeHash,
        @ExpiresAt = ExpiresAt,
        @FailedAttempts = FailedAttempts
    FROM dbo.OtpCodes WITH (UPDLOCK)
    WHERE Mobile = @Mobile AND UsedAt IS NULL
    ORDER BY Id DESC;

    IF @Id IS NULL OR @ExpiresAt < @Now
    BEGIN
        COMMIT TRANSACTION;
        SELECT N'Expired' AS Status;
        RETURN;
    END

    IF @FailedAttempts >= 5
    BEGIN
        COMMIT TRANSACTION;
        SELECT N'Locked' AS Status;
        RETURN;
    END

    IF @StoredHash <> @CodeHash
    BEGIN
        UPDATE dbo.OtpCodes SET FailedAttempts = FailedAttempts + 1 WHERE Id = @Id;
        COMMIT TRANSACTION;
        SELECT N'Invalid' AS Status;
        RETURN;
    END

    UPDATE dbo.OtpCodes SET UsedAt = @Now WHERE Id = @Id;
    COMMIT TRANSACTION;
    SELECT N'Ok' AS Status;
END
GO

-- Finds the user of a mobile number, creates a Customer when there is none.
CREATE OR ALTER PROCEDURE dbo.Users_GetOrCreateByMobile
    @Mobile NVARCHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Mobile = @Mobile)
    BEGIN
        INSERT INTO dbo.Users (Mobile) VALUES (@Mobile);
    END

    SELECT Id, Mobile, Email, PasswordHash, Role
    FROM dbo.Users
    WHERE Mobile = @Mobile;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Role
    FROM dbo.Users
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Users_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Mobile, Email, PasswordHash, Role
    FROM dbo.Users
    WHERE Email = @Email;
END
GO

-- Sets email + password hash for a user. Returns Status: 'Ok' | 'EmailTaken'.
CREATE OR ALTER PROCEDURE dbo.Users_SetCredentials
    @Id           INT,
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email AND Id <> @Id)
    BEGIN
        SELECT N'EmailTaken' AS Status;
        RETURN;
    END

    UPDATE dbo.Users
    SET Email = @Email,
        PasswordHash = @PasswordHash
    WHERE Id = @Id;

    SELECT N'Ok' AS Status;
END
GO

-- Password reset: only for accounts that already have an email + password. Returns AffectedRows (0 = none).
CREATE OR ALTER PROCEDURE dbo.Users_ResetPassword
    @Mobile       NVARCHAR(11),
    @PasswordHash NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET PasswordHash = @PasswordHash
    WHERE Mobile = @Mobile AND PasswordHash IS NOT NULL;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO

-- Run by hand to make someone an admin, e.g.:  EXEC dbo.Users_SetRole @Mobile = N'09120000000', @Role = N'Admin';
-- The person must have logged in once (so the user row exists). Returns AffectedRows (0 = no such user).
CREATE OR ALTER PROCEDURE dbo.Users_SetRole
    @Mobile NVARCHAR(11),
    @Role   NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users SET Role = @Role WHERE Mobile = @Mobile;

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
