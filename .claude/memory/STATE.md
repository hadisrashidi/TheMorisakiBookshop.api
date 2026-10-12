# State

Onboarding: done (2026-10-07)

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- All endpoints return the `CustomActionResult` envelope (always HTTP 200; 400 validation / 500 error with same shape).
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), `Controllers/Management/BooksManagementController.cs` (create/update/delete books, no auth yet).
- Data = SQL Server via Dapper + stored procedures: `Repositories/BooksRepository.cs`, `AuthorsRepository.cs`, `ReviewsRepository.cs` (concrete classes, `AddScoped` in `Program.cs`, connection string `ConnectionStrings:Bookshop`). Models: `*OutputModel`, `Models/Dto/*RequestModel`. Old `Data/*.json` files still in the repo (unused) until she confirms the DB works.
- Packages `Dapper` + `Microsoft.Data.SqlClient` added; `ConnectionStrings:Bookshop` in both appsettings files. `Database/Migrations/0001_create_database.sql` (collation `Persian_100_CI_AI`), `0002_create_catalog_tables.sql`, `0003_seed_catalog.sql` written, she ran 0001-0003 on Docker SQL Server (2026-10-12, OK). She ran procedure scripts `0004`-`0007` (2026-10-12, OK).
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 0: tasks 1-6 done and confirmed working by her (2026-10-12: UI shows books from SQL Server through the API). Next: delete `Data/*.json` + csproj item (waiting for her OK), then phase 1. Then task 7 (UI) / phase 1.

## Session log
### 2026-10-12 — Tasks 5+6: Dapper repositories + renames (web session, branch `claude/friendly-pascal-icidjv`)
- Did: she ran 0004-0007 OK. Replaced JSON repos + interfaces with `BooksRepository` / `AuthorsRepository` / `ReviewsRepository` (Dapper, stored procedures, `CancellationToken`); models renamed to `*OutputModel`; `BookRequests.cs` split into `CreateBookRequestModel` / `UpdateBookRequestModel` (+ `BookSpecRequestModel`); controllers take `CancellationToken`, `SearchBooks` uses `List<string>`; `ReviewsController` no longer needs the books repository (`Reviews_GetByAuthorId`). Specs loaded for every book list through `BookSpecs_GetByBookIds` (one extra call per list).
- Also: `Price`/`OldPrice` are numbers, books carry `Stock` + `InStock`; create/update take `stock`. Logged in BACKLOG "For the UI repo".
- Verified: `dotnet build` 0 warnings; app starts, DI resolves, DB error becomes the 500 envelope. NOT verified against a real database (none here) — she runs the API and reports errors.
- Confirmed by her 2026-10-12: everything works end to end (UI + API + SQL Server).
- Next: delete `Data/*.json` (ask her), then phase 1.
- Follow-up: UI got 500 on every call — her Docker maps host port 3698 to 1433, connection string said `localhost,1433` → changed to `localhost,3698` in both appsettings. Also warned: her SSMS tab was on `master` (scripts 0002-0007 may have run there; she checks `MorisakiBookshop.sys.procedures`), and port 3698 may be exposed publicly + `sa` password shared in chat → rotate, bind to 127.0.0.1.
- Follow-up 2: `Middleware/ExceptionHandlingMiddleware.cs` replaces `UseExceptionHandler` (logs + 500 envelope, Development adds exception message to `errors`); rule "new SQL scripts start with `USE MorisakiBookshop;` + `GO`" added to skill/README/DECISIONS. Verified: build ok, run without DB shows the SqlException in `errors` and the `fail:` log line.
- Found: UI shows no books because UI `*.api.service.ts` still expect raw JSON, API now sends the envelope (UI BACKLOG tasks 1 + 3) and `price` is a number now. Not fixed yet — asked her.
### 2026-10-12 — Task 4: stored procedures (web session, branch `claude/nifty-lovelace-e9tc1j`)
- Did: she ran 0001-0003 OK; wrote `0004_authors_procedures.sql`, `0005_book_specs_procedures.sql`, `0006_books_procedures.sql` (11 procs incl. Search with genres/languages/sort), `0007_reviews_procedures.sql`. Same behaviour as the JSON repositories (related/similar/featured ordering). No C# changed.
- Decisions: `Stock` vs `InStock` left to Claude → `Stock` only (final); specs as JSON into Insert/Update; read procs return `Stock`. Logged.
- Not verified: scripts never run (no SQL Server here) — she runs 0004-0007 and reports errors.
- Next: task 5 + 6.
### 2026-10-12 — Task 3: catalog tables + seed (web session, branch `claude/eager-hawking-eaaako`)
- Did: `0002_create_catalog_tables.sql` (Authors, Books, BookSpecs, Reviews; PK/FK/CHECK/indexes) and `0003_seed_catalog.sql` (generated from `Data/*.json`, same Ids, 12 authors / 13 books / specs / 26 reviews). Files saved with UTF-8 BOM so SSMS reads Persian correctly. No C# changed.
- Decisions: `Stock` replaces stored `InStock` (proposed, needs her OK); seed Stock = 10 placeholder. Logged.
- Not verified: scripts never run against SQL Server (I have none) — she runs them and reports errors.
- Next: she runs 0001-0003; then task 4.
<!-- newest on top, max 5 blocks, older ones go to archive/sessions.md -->
### 2026-10-11 — Task 2: packages, connection string, create-database script (web session, branch `claude/practical-pascal-zuq4fk`)
- Did: she merged the previous PR; added `Dapper` + `Microsoft.Data.SqlClient`; `ConnectionStrings:Bookshop` in `appsettings.json` and `appsettings.Development.json` (localhost,3698, `sa`, local throwaway password); `Database/Migrations/0001_create_database.sql` (`Persian_100_CI_AI`); updated migrations README. `dotnet build` ok (SDK re-installed via apt).
- Decisions: logged (password in both appsettings, collation, packages).
- Next: she starts Docker + runs 0001; then task 3.
### 2026-10-07 — Onboarding, planning, envelope (web session, both repos on branch `claude/magical-wozniak-j0qmxf`)
- Did: onboarding done; she told the project story and scope; agreed roadmap phases 0-6 → BACKLOG tasks 1-26; decisions logged (goal, login OTP + email/password, transactional orders, roadmap).
- Also: DB = SQL Server in Docker (`sa`, local password in appsettings.Development.json), prices `DECIMAL(18,0)`, guest cart in browser; updated CLAUDE.md, ONBOARDING.md, skill `sql-server-dapper` connection string accordingly.
- Result: memory + instruction files only, no app code changed. UI repo memory updated to match.
- Started implementing: BACKLOG task 1 done (envelope in code, controllers wrapped, `dotnet build` ok, curl-tested). .NET 8 SDK had to be installed in the sandbox via apt (dotnet.microsoft.com is blocked there).
- Next: task 2.
