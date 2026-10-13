# State

Onboarding: done (2026-10-07)

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- All endpoints return the `CustomActionResult` envelope (always HTTP 200; 400 validation / 500 error with same shape).
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), `Controllers/Management/BooksManagementController.cs` (create/update/delete books, Admin role required).
- Data = SQL Server via Dapper + stored procedures: `Repositories/BooksRepository.cs`, `AuthorsRepository.cs`, `ReviewsRepository.cs` (concrete classes, `AddScoped` in `Program.cs`, connection string `ConnectionStrings:Bookshop`). Models: `*OutputModel`, `Models/Dto/*RequestModel`. `Data/*.json` deleted (2026-10-13).
- Packages `Dapper` + `Microsoft.Data.SqlClient` added; `ConnectionStrings:Bookshop` in both appsettings files. `Database/Migrations/0001_create_database.sql` (collation `Persian_100_CI_AI`), `0002_create_catalog_tables.sql`, `0003_seed_catalog.sql` written, she ran 0001-0003 on Docker SQL Server (2026-10-12, OK). She ran procedure scripts `0004`-`0007` (2026-10-12, OK).
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- Auth (code written 2026-10-13, scripts 0010-0011 not run yet): `Controllers/Shop/AuthController.cs` (`RequestOtp`, `VerifyOtp`, `LoginWithPassword`, `SetCredentials`, `ResetPassword`, `GetMe`), JWT bearer (`Program.cs`, `Security/JwtTokenService.cs`), `Security/OtpService.cs`, `PasswordService.cs` (PBKDF2), `SmsSender.cs` (MOCK: code only in the log). `BooksManagementController` needs role `Admin`. Tables `Users`, `OtpCodes`.
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 2 API done in code (tasks 11-14 below). She runs 0010+0011, makes herself Admin, then the UI login screens (UI BACKLOG 5 + 13) replace the fake auth. Real SMS provider still open (mock for now).

## Session log
### 2026-10-13 — Phase 2 API: OTP + email/password login, JWT, roles (web session, branch `claude/adoring-rubin-tb785m`)
- Did: deleted `Data/*.json` + csproj item (her OK). Added NuGet `Microsoft.AspNetCore.Authentication.JwtBearer` 8.0.31 (her OK). Scripts `0010_create_auth_tables.sql` (Users, OtpCodes), `0011_auth_procedures.sql` (OTP create/verify with limits, user procs, `Users_SetRole`). C#: `AuthController`, `UsersRepository`, `OtpCodesRepository`, `Security/*`, request/output models, `Program.cs` JWT + 401/403 envelope, `[Authorize(Roles = "Admin")]` on `BooksManagementController`. `Jwt:Key` only in `appsettings.Development.json`.
- Verified: `dotnet build` 0 warnings; app starts; admin endpoint = 401 envelope without token, 403 with a Customer token, passes auth with an Admin token; bad mobile = 400 envelope. NOT verified: scripts 0010-0011 never run (no SQL Server here), no real OTP/login round trip.
- Follow-up: she could not find the code in the log → Development-only `Sms:ShowCodeInResponse` shows it in `message` of `RequestOtp` (DECISIONS). Build ok, not run.
- She ran 0010-0011: OTP login works (user 1 created). Then: Swagger "Authorize" button (`AddSecurityDefinition` in `Program.cs`) and UI login screens (UI repo, same branch). She has no direct repo access on her work PC: delivery = branch ZIP via the VM; list changed/added/deleted files at the end of each reply.
- Next: she makes herself Admin (`Users_SetRole`), tests the UI login against the real API.
- Follow-up: all API messages + validation errors translated to Persian (see DECISIONS); build ok, 400/401 verified with curl. Open: does she want a real sign-up form (BACKLOG question).
### 2026-10-12 — Task 8b: search filters endpoint (web session, same branch)
- Did: she ran 0008, search works. Wrote `0009_books_filters_procedure.sql`, `BookFiltersOutputModel`, `BooksRepository.GetFiltersAsync`, `Books/GetSearchFilters`; UI search page now takes genres/languages from it and has author + price filters.
- Verified: `dotnet build` 0 warnings, UI build ok. NOT verified: 0009 never run, no browser test.
- Next: she runs 0009; delete `Data/*.json` (her OK); then phase 2 decisions (SMS provider, OTP rules).
### 2026-10-12 — Task 10 audit + Task 8 search paging (web session, branch `claude/vibrant-dijkstra-3beh1b`, both repos)
- Did: audited the UI (findings in UI BACKLOG 9-14: fake auth incl. unverified password reset, fake checkout, footer/FAQ placeholders, hand-typed genre lists). Wrote `0008_books_search_paging.sql`; `BookSearchOutputModel`; `BooksRepository.SearchAsync` uses `QueryMultipleAsync`; `SearchBooks` has `authorId`, `minPrice`, `maxPrice`, `page`, `pageSize`. UI search switched to server paging.
- Verified: `dotnet build` 0 warnings, UI `npm run build` ok. NOT verified: script 0008 never run (no SQL Server here), nothing tested in a browser.
- Next: she runs 0008; then facets (8b) + price/author controls in the UI.
### 2026-10-12 — Tasks 5+6: Dapper repositories + renames (web session, branch `claude/friendly-pascal-icidjv`)
- Did: she ran 0004-0007 OK. Replaced JSON repos + interfaces with `BooksRepository` / `AuthorsRepository` / `ReviewsRepository` (Dapper, stored procedures, `CancellationToken`); models renamed to `*OutputModel`; `BookRequests.cs` split into `CreateBookRequestModel` / `UpdateBookRequestModel` (+ `BookSpecRequestModel`); controllers take `CancellationToken`, `SearchBooks` uses `List<string>`; `ReviewsController` no longer needs the books repository (`Reviews_GetByAuthorId`). Specs loaded for every book list through `BookSpecs_GetByBookIds` (one extra call per list).
- Also: `Price`/`OldPrice` are numbers, books carry `Stock` + `InStock`; create/update take `stock`. Logged in BACKLOG "For the UI repo".
- Verified: `dotnet build` 0 warnings; app starts, DI resolves, DB error becomes the 500 envelope. NOT verified against a real database (none here) — she runs the API and reports errors.
- Confirmed by her 2026-10-12: everything works end to end (UI + API + SQL Server).
- Next: delete `Data/*.json` (ask her), then phase 1.
- Follow-up: UI got 500 on every call — her Docker maps host port 3698 to 1433, connection string said `localhost,1433` → changed to `localhost,3698` in both appsettings. Also warned: her SSMS tab was on `master` (scripts 0002-0007 may have run there; she checks `MorisakiBookshop.sys.procedures`), and port 3698 may be exposed publicly + `sa` password shared in chat → rotate, bind to 127.0.0.1.
- Follow-up 2: `Middleware/ExceptionHandlingMiddleware.cs` replaces `UseExceptionHandler` (logs + 500 envelope, Development adds exception message to `errors`); rule "new SQL scripts start with `USE MorisakiBookshop;` + `GO`" added to skill/README/DECISIONS. Verified: build ok, run without DB shows the SqlException in `errors` and the `fail:` log line.
- Found: UI shows no books because UI `*.api.service.ts` still expect raw JSON, API now sends the envelope (UI BACKLOG tasks 1 + 3) and `price` is a number now. Not fixed yet — asked her.
