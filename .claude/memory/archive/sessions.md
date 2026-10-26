# Archived sessions
### 2026-10-19 — Admin panel: books, stock, authors, image upload (web session, branch `claude/loving-gauss-lh47dz`; admin code later moved to the new admin repos)
- Her choices: upload covers from the panel; hide books (`IsActive`) instead of deleting; add/edit authors too (DECISIONS 2026-10-19).
- Did: scripts `0013_books_is_active.sql` (column, all shop procedures filter active, `Books_Search`/`Books_GetById` take `@IncludeInactive`, new `Books_SetStock`/`Books_SetActive`, `Books_Delete` dropped) and `0014_authors_management_procedures.sql`. C#: `BookOutputModel.IsActive`, `BooksRepository` (includeInactive flag, `SetStockAsync`, `SetActiveAsync`, delete removed), `AuthorsRepository` insert/update, `BooksManagementController` rewritten, new `AuthorsManagementController`, `ImagesManagementController`, `Storage/ImageStorage`, request models, `MaxLength` on book/author DTOs (+ removed duplicate `MinLength(1)` next to `[Required]`), author must exist on create/update book (Persian message instead of a 500).
- Verified: `dotnet build` 0 warnings; app started, upload endpoint with a minted token: no token 401, Customer 403, Admin OK, bad extension / folder / size / no file answer Persian envelope, file served at `/uploads/...` (200 image/png); author DTO validation 400. UI: `npm run build` ok + Playwright run against a MOCKED API (list, stock save, hide, upload, create, edit, author create, customer kept out of `/admin`). NOT verified: scripts 0013-0014 never run (no SQL Server here), no real database round trip.
- Follow-up (same day): she wanted SEPARATE repos for admin. Created `TheMorisakiBookshop.admin.api` + `.admin.ui` (she made the empty repos), moved the admin code there (own login, DECISIONS), then removed it from the shop: deleted `Controllers/Management/*`, `Storage/ImageStorage.cs`, admin request models, `BooksRepository` Insert/Update/SetStock/SetActive + `includeInactive` flag, `AuthorsRepository` Insert/Update. Kept: scripts 0013-0014 (they are the database), `IsActive`, static `/uploads`. `Uploads:RootPath` now `../uploads`. Verified: `dotnet build` 0 warnings; shop app starts, serves `/uploads/...` (200), old `BooksManagement/*` route = 404.
- Next: she runs 0013 + 0014, makes herself Admin (+ email/password via `/security`), tests the admin repos.
### 2026-10-13 — Phase 2 API: OTP + email/password login, JWT, roles (web session, branch `claude/adoring-rubin-tb785m`)
- Did: deleted `Data/*.json` + csproj item (her OK). Added NuGet `Microsoft.AspNetCore.Authentication.JwtBearer` 8.0.31 (her OK). Scripts `0010_create_auth_tables.sql` (Users, OtpCodes), `0011_auth_procedures.sql` (OTP create/verify with limits, user procs, `Users_SetRole`). C#: `AuthController`, `UsersRepository`, `OtpCodesRepository`, `Security/*`, request/output models, `Program.cs` JWT + 401/403 envelope, `[Authorize(Roles = "Admin")]` on `BooksManagementController`. `Jwt:Key` only in `appsettings.Development.json`.
- Verified: `dotnet build` 0 warnings; app starts; admin endpoint = 401 envelope without token, 403 with a Customer token, passes auth with an Admin token; bad mobile = 400 envelope. NOT verified: scripts 0010-0011 never run (no SQL Server here), no real OTP/login round trip.
- Follow-up: she could not find the code in the log → Development-only `Sms:ShowCodeInResponse` shows it in `message` of `RequestOtp` (DECISIONS). Build ok, not run.
- She ran 0010-0011: OTP login works (user 1 created). Then: Swagger "Authorize" button (`AddSecurityDefinition` in `Program.cs`) and UI login screens (UI repo, same branch). She has no direct repo access on her work PC: delivery = branch ZIP via the VM; list changed/added/deleted files at the end of each reply.
- Next: she makes herself Admin (`Users_SetRole`), tests the UI login against the real API.
- Follow-up: all API messages + validation errors translated to Persian (see DECISIONS); build ok, 400/401 verified with curl. Then `Auth/Register` added (email + password sign-up, DECISIONS); build ok, not run against a DB.
- Follow-up: `RememberMe` on the three login endpoints (30-day token, DECISIONS); build ok, not run against a DB.
- Follow-up: `Users.Name` (script 0012), `Register` takes `name`, `Auth/UpdateProfile`; build ok, script not run.
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
<!-- newest on top -->
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
### 2026-10-04 — Claude setup (done locally by a helper, not a web session)
- Did: created `.claude/` (CLAUDE.md, memory, skills `dotnet-simple` + `sql-server-dapper`, Stop hook), `Database/Migrations/README.md`.
- Also: basic rules from helper's own .NET skill added to `dotnet-simple` / `sql-server-dapper` (model suffixes, `CancellationToken`, `List<T>`, empty lists). Existing code not renamed yet → BACKLOG task 6. Added `CustomActionResult` envelope rules to `dotnet-simple` (needed by the UI's `ApiResponse<T>`); not in code yet → BACKLOG task 1.
- Result: setup only, no app code changed.
- Next: onboarding, then backlog item 1.
