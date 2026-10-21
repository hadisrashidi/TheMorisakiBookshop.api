# State

Onboarding: done (2026-10-07)

## Current state
- ASP.NET Core Web API, .NET 8 (`TheMorisakiBookshop.csproj`), Swagger in Development.
- Routes: `api/[controller]/[action]` from `Controllers/BaseController.cs`; only `[HttpGet]` / `[HttpPost]` used.
- All endpoints return the `CustomActionResult` envelope (always HTTP 200; 400 validation / 500 error with same shape).
- Controllers: `Controllers/Shop/` (Books, Authors, Reviews — read only), no write endpoints for the catalog: books/authors/images are managed by the separate admin API repo (`TheMorisakiBookshop.admin.api`).
- Data = SQL Server via Dapper + stored procedures: `Repositories/BooksRepository.cs`, `AuthorsRepository.cs`, `ReviewsRepository.cs` (concrete classes, `AddScoped` in `Program.cs`, connection string `ConnectionStrings:Bookshop`). Models: `*OutputModel`, `Models/Dto/*RequestModel`. `Data/*.json` deleted (2026-10-13).
- Packages `Dapper` + `Microsoft.Data.SqlClient` added; `ConnectionStrings:Bookshop` in both appsettings files. `Database/Migrations/0001_create_database.sql` (collation `Persian_100_CI_AI`), `0002_create_catalog_tables.sql`, `0003_seed_catalog.sql` written, she ran 0001-0003 on Docker SQL Server (2026-10-12, OK). She ran procedure scripts `0004`-`0007` (2026-10-12, OK).
- CORS origins from `Cors:AllowedOrigins` (Development: `http://localhost:4200`).
- Auth (code written 2026-10-13, scripts 0010-0011 not run yet): `Controllers/Shop/AuthController.cs` (`RequestOtp`, `VerifyOtp`, `LoginWithPassword`, `SetCredentials`, `ResetPassword`, `GetMe`), JWT bearer (`Program.cs`, `Security/JwtTokenService.cs`), `Security/OtpService.cs`, `PasswordService.cs` (PBKDF2), `SmsSender.cs` (MOCK: code only in the log). `BooksManagementController` needs role `Admin`. Tables `Users`, `OtpCodes`.
- Admin: separate repos `TheMorisakiBookshop.admin.api` / `.admin.ui` (same database; THIS repo owns all SQL scripts). Shop side: `Books.IsActive` (hidden books; script 0013, not run yet), shop procedures return active books only; `Program.cs` serves the uploads folder `Uploads:RootPath` (default `../uploads`) at `/uploads` — must be the same folder the admin API writes to.
- Orders (code written 2026-10-21, scripts 0015-0016 not run yet): `Controllers/Shop/OrdersController.cs` (`PlaceOrder`, `GetMyOrders`, both `[Authorize]`), `Repositories/OrdersRepository.cs`, tables `Orders`, `OrderLines`. Status starts `PendingPayment`, no payment yet.
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 2 (accounts) done; phase 5 started in the separate admin repos (2026-10-19). She runs 0013 + 0014, then tests admin.ui. Still open in phase 5: orders admin (after phase 3). Real SMS provider still open (mock for now). Phase 3 started 2026-10-21: orders API written (she runs 0015 + 0016); next the shop UI checkout (UI BACKLOG task 6), then the admin orders screens (admin repos, read only first).

## Session log
### 2026-10-21 — Phase 3 start: orders API (web session, branch `claude/gifted-curie-7qha13`; admin repos attached but untouched)
- Her request: an orders section in the admin panel. Found: no orders exist (shop checkout is fake, localStorage) -> order of work: shop orders API, shop UI checkout, then admin list. She agreed with: cart stays in localStorage, status `PendingPayment` (DECISIONS 2026-10-21).
- Did: scripts `0015_create_orders_tables.sql`, `0016_orders_procedures.sql`; C#: `OrdersController`, `OrdersRepository`, `OrderOutputModel`, `OrderLineOutputModel`, `OrderPlacedModel`, `PlaceOrderRequestModel`, `OrderLineRequestModel`, `OrdersRepository` registered in `Program.cs`. Contract in "For the UI repo".
- Verified: `dotnet build` 0 warnings (installed .NET 8 SDK in the VM with apt); both endpoints answer the 401 envelope without a token. NOT verified: scripts 0015-0016 never run (no SQL Server here), no real order round trip.
- Next: she runs 0015 + 0016; UI checkout calls `PlaceOrder`; then `Orders_Search` / `Orders_GetById` / status procedures (script 0017) + admin.api / admin.ui screens.
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
