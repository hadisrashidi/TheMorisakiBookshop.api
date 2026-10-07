---
name: sql-server-dapper
description: Use for EVERY database task in this repo — creating or changing tables, seed data, stored procedures, migration scripts in Database/Migrations, and repository classes that call stored procedures with Dapper. Encodes naming, the re-runnable script rules, SQL Server templates and the matching Dapper C# templates. Read before writing any SQL or any repository code.
---

# SQL Server + stored procedures + Dapper

The owner runs every script herself on her local SQL Server. You never connect to a database.
SQL must be as readable as the C# (skill `dotnet-simple`).

## Naming

| Thing | Rule | Example |
|---|---|---|
| Database | `MorisakiBookshop` | |
| Schema | `dbo` | |
| Table | PascalCase, plural | `dbo.Books`, `dbo.BookSpecs` |
| Column | PascalCase, **identical to the C# property** | `Title`, `AuthorId`, `AddedAt` |
| Primary key | `Id INT IDENTITY(1,1)` | `CONSTRAINT PK_Books PRIMARY KEY (Id)` |
| Foreign key | `FK_<Table>_<RefTable>` | `FK_Books_Authors` |
| Index | `IX_<Table>_<Columns>` | `IX_Books_AuthorId` |
| Stored procedure | `dbo.<Table>_<Action>` | `dbo.Books_GetById`, `dbo.Books_Search` |
| SP parameter | `@` + column name | `@AuthorId` |

Column = SP parameter = C# property name (`Title` ↔ `@Title` ↔ `BookOutputModel.Title`), so Dapper maps columns to properties with no mapping code.

## Migration scripts — `Database/Migrations/`

- File name: `NNNN_short_description.sql`, 4 digits, next free number. `0001_create_authors_table.sql`.
- **Every script is re-runnable**: running it twice (or on a DB where it already ran) succeeds and changes nothing.
- **Never edit a script that was already delivered.** Any change = a new file. To change a stored
  procedure, the new file contains the full `CREATE OR ALTER PROCEDURE`.
- One topic per file (one table, or the procedures of one table). Separate batches with `GO`.
- No `USE` statement — she picks the database in SSMS.
- After writing a script: add it to `.claude/memory/BACKLOG.md` → "SQL to run", and tell her in chat.
- Never put real secrets or personal data in scripts.

Header for every file:
```sql
-- 0002_create_books_table.sql
-- Creates dbo.Books and its foreign key to dbo.Authors.
-- Safe to run more than once.
```

### Re-runnable patterns

```sql
-- Table
IF OBJECT_ID(N'dbo.Books', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Books
    (
        Id          INT            IDENTITY(1,1) NOT NULL,
        Title       NVARCHAR(200)  NOT NULL,
        AuthorId    INT            NOT NULL,
        InStock     BIT            NOT NULL CONSTRAINT DF_Books_InStock DEFAULT (1),
        AddedAt     DATETIME2(0)   NOT NULL CONSTRAINT DF_Books_AddedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Books PRIMARY KEY (Id)
    );
END
GO

-- Add a column
IF COL_LENGTH(N'dbo.Books', N'Language') IS NULL
BEGIN
    ALTER TABLE dbo.Books ADD Language NVARCHAR(50) NOT NULL CONSTRAINT DF_Books_Language DEFAULT (N'');
END
GO

-- Drop a column
IF COL_LENGTH(N'dbo.Books', N'OldColumn') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Books DROP COLUMN OldColumn;
END
GO

-- Foreign key
IF OBJECT_ID(N'dbo.FK_Books_Authors', N'F') IS NULL
BEGIN
    ALTER TABLE dbo.Books
        ADD CONSTRAINT FK_Books_Authors FOREIGN KEY (AuthorId) REFERENCES dbo.Authors (Id);
END
GO

-- Index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Books_AuthorId' AND object_id = OBJECT_ID(N'dbo.Books'))
BEGIN
    CREATE INDEX IX_Books_AuthorId ON dbo.Books (AuthorId);
END
GO

-- Seed rows with fixed Ids (only the missing ones)
SET IDENTITY_INSERT dbo.Authors ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 1)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image) VALUES (1, N'...', N'/authors/1.png');
END

SET IDENTITY_INSERT dbo.Authors OFF;
GO
```
- Text is always `NVARCHAR` and literals are `N'...'` (the data is Persian).
- Name every constraint (`DF_`, `PK_`, `FK_`) — unnamed ones get random names and can't be dropped by name later.

### Type mapping

| C# | SQL Server |
|---|---|
| `int` | `INT` |
| `string` | `NVARCHAR(n)` (`NVARCHAR(MAX)` only for long text like Description) |
| `bool` | `BIT` |
| `decimal` | `DECIMAL(p, s)` |
| `DateTime` | `DATETIME2(0)` (UTC) |
| `int?`, `string?` | same type, `NULL` allowed |

## Stored procedure templates

Rules: `CREATE OR ALTER`, `SET NOCOUNT ON`, explicit column list (never `SELECT *`),
filtering / sorting / joins happen here — not in C#.

```sql
CREATE OR ALTER PROCEDURE dbo.Books_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, InStock, AddedAt
    FROM dbo.Books
    WHERE Id = @Id;
END
GO

-- Optional filters: NULL means "don't filter". Lists come as comma-separated text.
CREATE OR ALTER PROCEDURE dbo.Books_Search
    @Query       NVARCHAR(200) = NULL,
    @Genres      NVARCHAR(MAX) = NULL,  -- e.g. N'رمان,شعر'
    @InStockOnly BIT           = 0,
    @Sort        NVARCHAR(20)  = NULL   -- 'price_asc' | 'price_desc' | 'newest'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Title, AuthorId, Genre, Price, InStock, AddedAt
    FROM dbo.Books
    WHERE (@Query IS NULL OR Title LIKE N'%' + @Query + N'%')
      AND (@Genres IS NULL OR Genre IN (SELECT value FROM STRING_SPLIT(@Genres, N',')))
      AND (@InStockOnly = 0 OR InStock = 1)
    ORDER BY
        CASE WHEN @Sort = 'price_asc'  THEN Price END ASC,
        CASE WHEN @Sort = 'price_desc' THEN Price END DESC,
        CASE WHEN @Sort = 'newest'     THEN AddedAt END DESC,
        Id;
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_Insert
    @Title    NVARCHAR(200),
    @AuthorId INT,
    @InStock  BIT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Books (Title, AuthorId, InStock)
    VALUES (@Title, @AuthorId, @InStock);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;   -- the new Id
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_Update
    @Id       INT,
    @Title    NVARCHAR(200),
    @AuthorId INT,
    @InStock  BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Books
    SET Title = @Title,
        AuthorId = @AuthorId,
        InStock = @InStock
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO

CREATE OR ALTER PROCEDURE dbo.Books_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.Books WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;   -- 0 = not found
END
GO
```
Writes touching several tables (e.g. a book and its specs): one procedure,
`SET XACT_ABORT ON;` + `BEGIN TRANSACTION` / `COMMIT TRANSACTION`, so it is all-or-nothing.

## Dapper repository template

Packages: `Dapper`, `Microsoft.Data.SqlClient` (ask her before adding them the first time).
Connection string in `appsettings.Development.json` (local SQL Server in Docker, `sa` login, local-only throwaway password):
```json
"ConnectionStrings": {
  "Bookshop": "Server=localhost,1433;Database=MorisakiBookshop;User Id=sa;Password=<her local password>;TrustServerCertificate=True;"
}
```

```csharp
using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

namespace TheMorisakiBookshop.Repositories
{
    public class BooksRepository
    {
        private readonly string _connectionString;

        public BooksRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        // One row (or null = not found)
        public async Task<BookOutputModel?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetById",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                BookOutputModel? book = await connection.QueryFirstOrDefaultAsync<BookOutputModel>(command);

                return book;
            }
        }

        // Many rows (empty list when nothing matches, never null)
        public async Task<List<BookOutputModel>> SearchAsync(string? query, string? genres, bool inStockOnly, string? sort, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Query", query);
                parameters.Add("@Genres", genres);
                parameters.Add("@InStockOnly", inStockOnly);
                parameters.Add("@Sort", sort);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Search",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> books = await connection.QueryAsync<BookOutputModel>(command);

                return books.ToList();
            }
        }

        // Insert: returns the new Id
        public async Task<int> InsertAsync(CreateBookRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Title", request.Title);
                parameters.Add("@AuthorId", request.AuthorId);
                parameters.Add("@InStock", request.InStock);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Insert",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int newId = await connection.ExecuteScalarAsync<int>(command);

                return newId;
            }
        }

        // Update / Delete: returns true when a row was found
        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Delete",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }
    }
}
```
Rules:
- One repository per table, one method per stored procedure, method name = action (`Books_GetById` → `GetByIdAsync`).
- Always `DynamicParameters` with explicit `@Name`, always a `CommandDefinition` with `CommandType.StoredProcedure` and the `cancellationToken` (one style everywhere).
- Methods return `List<T>` (`.ToList()` on the Dapper result) or a single `T?`; never `IEnumerable<T>`, never a null list.
- Open the connection in a `using (...) { }` block inside each method; Dapper opens/closes it. No shared connection field.
- Parent + child rows (book + specs): call two procedures (`Books_GetById`, `BookSpecs_GetByBookId`) and assign `book.Specs = specs;`. Do not use Dapper multi-mapping.
- Register with `builder.Services.AddScoped<BooksRepository>();`.

## Before you finish
- Script is re-runnable (mentally run it twice), has the header, is listed in BACKLOG "SQL to run".
- Every SP parameter name = column name = C# property name.
- No SQL text in C#; no LINQ besides `.ToList()`.
- If a response shape or route changed: add it to BACKLOG "For the UI repo".
