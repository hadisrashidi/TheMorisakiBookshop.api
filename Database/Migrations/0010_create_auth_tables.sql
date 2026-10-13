USE MorisakiBookshop;
GO

-- 0010_create_auth_tables.sql
-- Creates dbo.Users (accounts) and dbo.OtpCodes (one-time login codes).
-- Safe to run more than once.

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        Id           INT            IDENTITY(1,1) NOT NULL,
        Mobile       NVARCHAR(11)   NOT NULL,
        Email        NVARCHAR(256)  NULL,
        PasswordHash NVARCHAR(200)  NULL,
        Role         NVARCHAR(20)   NOT NULL CONSTRAINT DF_Users_Role DEFAULT (N'Customer'),
        CreatedAt    DATETIME2(0)   NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Users PRIMARY KEY (Id),
        CONSTRAINT CK_Users_Role CHECK (Role IN (N'Customer', N'Admin'))
    );
END
GO

-- One account per mobile number.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Users_Mobile' AND object_id = OBJECT_ID(N'dbo.Users'))
BEGIN
    CREATE UNIQUE INDEX UX_Users_Mobile ON dbo.Users (Mobile);
END
GO

-- One account per email; many accounts may have no email yet (NULL), so only non-NULL emails are unique.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Users_Email' AND object_id = OBJECT_ID(N'dbo.Users'))
BEGIN
    CREATE UNIQUE INDEX UX_Users_Email ON dbo.Users (Email) WHERE Email IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.OtpCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OtpCodes
    (
        Id             INT            IDENTITY(1,1) NOT NULL,
        Mobile         NVARCHAR(11)   NOT NULL,
        CodeHash       NVARCHAR(100)  NOT NULL,
        ExpiresAt      DATETIME2(0)   NOT NULL,
        FailedAttempts INT            NOT NULL CONSTRAINT DF_OtpCodes_FailedAttempts DEFAULT (0),
        UsedAt         DATETIME2(0)   NULL,
        CreatedAt      DATETIME2(0)   NOT NULL CONSTRAINT DF_OtpCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_OtpCodes PRIMARY KEY (Id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OtpCodes_Mobile_CreatedAt' AND object_id = OBJECT_ID(N'dbo.OtpCodes'))
BEGIN
    CREATE INDEX IX_OtpCodes_Mobile_CreatedAt ON dbo.OtpCodes (Mobile, CreatedAt);
END
GO
