# State

Onboarding: done (2026-10-07)

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- All endpoints return the `CustomActionResult` envelope (always HTTP 200; 400 validation / 500 error with same shape).
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), `Controllers/Management/BooksManagementController.cs` (create/update/delete books, no auth yet).
- Data today = JSON files in `Data/` (Books, Authors, Reviews) read by `Repositories/Json*Repository.cs` behind `I*Repository` interfaces. In-memory cache + `SemaphoreSlim`, filtering/sorting done with LINQ in C#.
- Dapper / SQL Server not added yet. `Database/Migrations/` exists, no scripts yet.
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 0 started. Task 1 (envelope) done. Next: task 2 (Dapper + SqlClient packages — ask her first).

## Session log
<!-- newest on top, max 5 blocks, older ones go to archive/sessions.md -->
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
