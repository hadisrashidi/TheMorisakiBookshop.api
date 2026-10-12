-- 0002_create_catalog_tables.sql
-- Creates dbo.Authors, dbo.Books, dbo.BookSpecs, dbo.Reviews with keys, foreign keys and indexes.
-- Run against MorisakiBookshop. Safe to run more than once.

IF OBJECT_ID(N'dbo.Authors', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Authors
    (
        Id     INT           IDENTITY(1,1) NOT NULL,
        Name   NVARCHAR(100) NOT NULL,
        Image  NVARCHAR(200) NOT NULL CONSTRAINT DF_Authors_Image DEFAULT (N''),
        Bio    NVARCHAR(MAX) NOT NULL CONSTRAINT DF_Authors_Bio   DEFAULT (N''),
        Genre  NVARCHAR(50)  NOT NULL CONSTRAINT DF_Authors_Genre DEFAULT (N''),
        CONSTRAINT PK_Authors PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Books', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Books
    (
        Id           INT            IDENTITY(1,1) NOT NULL,
        Title        NVARCHAR(200)  NOT NULL,
        AuthorId     INT            NOT NULL,
        Price        DECIMAL(18,0)  NOT NULL,
        OldPrice     DECIMAL(18,0)  NULL,           -- NULL = no discount
        Stock        INT            NOT NULL CONSTRAINT DF_Books_Stock DEFAULT (0),
        Image        NVARCHAR(200)  NOT NULL CONSTRAINT DF_Books_Image       DEFAULT (N''),
        Description  NVARCHAR(MAX)  NOT NULL CONSTRAINT DF_Books_Description DEFAULT (N''),
        Genre        NVARCHAR(50)   NOT NULL CONSTRAINT DF_Books_Genre       DEFAULT (N''),
        Language     NVARCHAR(50)   NOT NULL CONSTRAINT DF_Books_Language    DEFAULT (N''),
        AddedAt      DATETIME2(0)   NOT NULL CONSTRAINT DF_Books_AddedAt     DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Books PRIMARY KEY (Id),
        CONSTRAINT CK_Books_Stock CHECK (Stock >= 0)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_Books_Authors', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Books
        ADD CONSTRAINT FK_Books_Authors FOREIGN KEY (AuthorId) REFERENCES dbo.Authors (Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Books_AuthorId' AND object_id = OBJECT_ID(N'dbo.Books'))
BEGIN
    CREATE INDEX IX_Books_AuthorId ON dbo.Books (AuthorId);
END
GO

IF OBJECT_ID(N'dbo.BookSpecs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BookSpecs
    (
        Id         INT           IDENTITY(1,1) NOT NULL,
        BookId     INT           NOT NULL,
        SortOrder  INT           NOT NULL,          -- display order in the spec table
        Label      NVARCHAR(100) NOT NULL,
        Value      NVARCHAR(200) NOT NULL,
        CONSTRAINT PK_BookSpecs PRIMARY KEY (Id)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_BookSpecs_Books', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.BookSpecs
        ADD CONSTRAINT FK_BookSpecs_Books FOREIGN KEY (BookId) REFERENCES dbo.Books (Id) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BookSpecs_BookId' AND object_id = OBJECT_ID(N'dbo.BookSpecs'))
BEGIN
    CREATE INDEX IX_BookSpecs_BookId ON dbo.BookSpecs (BookId);
END
GO

IF OBJECT_ID(N'dbo.Reviews', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Reviews
    (
        Id            INT            IDENTITY(1,1) NOT NULL,
        BookId        INT            NOT NULL,
        ReviewerName  NVARCHAR(100)  NOT NULL,
        Rating        INT            NOT NULL,
        Text          NVARCHAR(2000) NOT NULL,
        Date          NVARCHAR(10)   NOT NULL,      -- Jalali text such as 1403/04/12, as the UI shows it
        CONSTRAINT PK_Reviews PRIMARY KEY (Id),
        CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5)
    );
END
GO

IF OBJECT_ID(N'dbo.FK_Reviews_Books', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Reviews
        ADD CONSTRAINT FK_Reviews_Books FOREIGN KEY (BookId) REFERENCES dbo.Books (Id) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Reviews_BookId' AND object_id = OBJECT_ID(N'dbo.Reviews'))
BEGIN
    CREATE INDEX IX_Reviews_BookId ON dbo.Reviews (BookId);
END
GO
