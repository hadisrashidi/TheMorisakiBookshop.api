# State

Onboarding: done (2026-10-07)

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- All endpoints return the `CustomActionResult` envelope (always HTTP 200; 400 validation / 500 error with same shape).
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), `Controllers/Management/BooksManagementController.cs` (create/update/delete books, no auth yet).
- Data today = JSON files in `Data/` (Books, Authors, Reviews) read by `Repositories/Json*Repository.cs` behind `I*Repository` interfaces. In-memory cache + `SemaphoreSlim`, filtering/sorting done with LINQ in C#.
- Packages `Dapper` + `Microsoft.Data.SqlClient` added; `ConnectionStrings:Bookshop` in both appsettings files (not used by code yet). `Database/Migrations/0001_create_database.sql` (collation `Persian_100_CI_AI`), `0002_create_catalog_tables.sql`, `0003_seed_catalog.sql` written, none run by her yet.
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 0: tasks 1, 3 (scripts written) done; waiting for her to run 0001, 0002, 0003 on Docker SQL Server. Next: task 4 (stored procedures).

## Session log
### 2026-10-12 — Task 3: catalog tables + seed (web session, branch `claude/eager-hawking-eaaako`)
- Did: `0002_create_catalog_tables.sql` (Authors, Books, BookSpecs, Reviews; PK/FK/CHECK/indexes) and `0003_seed_catalog.sql` (generated from `Data/*.json`, same Ids, 12 authors / 13 books / specs / 26 reviews). Files saved with UTF-8 BOM so SSMS reads Persian correctly. No C# changed.
- Decisions: `Stock` replaces stored `InStock` (proposed, needs her OK); seed Stock = 10 placeholder. Logged.
- Not verified: scripts never run against SQL Server (I have none) — she runs them and reports errors.
- Next: she runs 0001-0003; then task 4.
<!-- newest on top, max 5 blocks, older ones go to archive/sessions.md -->
### 2026-10-11 — Task 2: packages, connection string, create-database script (web session, branch `claude/practical-pascal-zuq4fk`)
- Did: she merged the previous PR; added `Dapper` + `Microsoft.Data.SqlClient`; `ConnectionStrings:Bookshop` in `appsettings.json` and `appsettings.Development.json` (localhost,1433, `sa`, local throwaway password); `Database/Migrations/0001_create_database.sql` (`Persian_100_CI_AI`); updated migrations README. `dotnet build` ok (SDK re-installed via apt).
- Decisions: logged (password in both appsettings, collation, packages).
- Next: she starts Docker + runs 0001; then task 3.
### 2026-10-07 — Onboarding, planning, envelope (web session, both repos on branch `claude/magical-wozniak-j0qmxf`)
- Did: onboarding done; she told the project story and scope; agreed roadmap phases 0-6 → BACKLOG tasks 1-26; decisions logged (goal, login OTP + email/password, transactional orders, roadmap).
- Also: DB = SQL Server in Docker (`sa`, local password in appsettings.Development.json), prices `DECIMAL(18,0)`, guest cart in browser; updated CLAUDE.md, ONBOARDING.md, skill `sql-server-dapper` connection string accordingly.
- Result: memory + instruction files only, no app code changed. UI repo memory updated to match.
- Started implementing: BACKLOG task 1 done (envelope in code, controllers wrapped, `dotnet build` ok, curl-tested). .NET 8 SDK had to be installed in the sandbox via apt (dotnet.microsoft.com is blocked there).
- Next: task 2.
### 2026-10-04 — Claude setup (done locally by a helper, not a web session)
- Did: created `.claude/` (CLAUDE.md, memory, skills `dotnet-simple` + `sql-server-dapper`, Stop hook), `Database/Migrations/README.md`.
- Also: basic rules from helper's own .NET skill added to `dotnet-simple` / `sql-server-dapper` (model suffixes, `CancellationToken`, `List<T>`, empty lists). Existing code not renamed yet → BACKLOG task 6. Added `CustomActionResult` envelope rules to `dotnet-simple` (needed by the UI's `ApiResponse<T>`); not in code yet → BACKLOG task 1.
- Result: setup only, no app code changed.
- Next: onboarding, then backlog item 1.
