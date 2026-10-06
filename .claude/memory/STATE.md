# State

Onboarding: pending

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), `Controllers/Management/BooksManagementController.cs` (create/update/delete books, no auth yet).
- Data today = JSON files in `Data/` (Books, Authors, Reviews) read by `Repositories/Json*Repository.cs` behind `I*Repository` interfaces. In-memory cache + `SemaphoreSlim`, filtering/sorting done with LINQ in C#.
- Dapper / SQL Server not added yet. `Database/Migrations/` exists, no scripts yet.
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- None. Next: first backlog item.

## Session log
<!-- newest on top, max 5 blocks, older ones go to archive/sessions.md -->
### 2026-10-04 — Claude setup (done locally by a helper, not a web session)
- Did: created `.claude/` (CLAUDE.md, memory, skills `dotnet-simple` + `sql-server-dapper`, Stop hook), `Database/Migrations/README.md`.
- Also: basic rules from helper's own .NET skill added to `dotnet-simple` / `sql-server-dapper` (model suffixes, `CancellationToken`, `List<T>`, empty lists). Existing code not renamed yet → BACKLOG task 6. Added `CustomActionResult` envelope rules to `dotnet-simple` (needed by the UI's `ApiResponse<T>`); not in code yet → BACKLOG task 1.
- Result: setup only, no app code changed.
- Next: onboarding, then backlog item 1.
