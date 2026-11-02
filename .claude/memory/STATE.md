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
- Orders (2026-10-21, scripts 0015-0018 run and tested by her 2026-10-24): `Controllers/Shop/OrdersController.cs` (`PlaceOrder`, `GetMyOrders`, both `[Authorize]`), `Repositories/OrdersRepository.cs`, tables `Orders`, `OrderLines`. Status starts `PendingPayment`, no payment yet.
- Addresses (2026-10-26, script 0020 run by her, round trip not reported yet): `Controllers/Shop/AddressesController.cs` (`GetMyAddresses`, `AddAddress`, `UpdateAddress`, `DeleteAddress`, `SetDefaultAddress`, all `[Authorize]`), `Repositories/AddressesRepository.cs`, table `Addresses`.
- Cart (2026-10-26, script 0021 run by her): `Controllers/Shop/CartController.cs` (`GetMyCart`, `SetQuantity`, `MergeCart`, `ClearCart`, all `[Authorize]`), `Repositories/CartRepository.cs`, table `CartItems`.
- Login lockout (2026-10-26, script 0022 run by her 2026-10-27, round trip not reported): `AuthController.LoginWithPassword` + `UsersRepository.RegisterFailedLoginAsync/ClearFailedLoginsAsync`, columns `Users.FailedLoginCount/LockedUntil`.
- Reviews (2026-10-27, script 0024 run by her, round trip not reported yet): `ReviewsController.GetMyReview` / `SaveReview` (`[Authorize]`, one review per user per book), `Reviews.UserId`; the read endpoints are public. Old seeded reviews have no user.
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 2 (accounts) done; phase 5 started in the separate admin repos (2026-10-19). She runs 0013 + 0014, then tests admin.ui. Still open in phase 5: orders admin (after phase 3). Real SMS provider still open (mock for now). Phase 3 started 2026-10-21: orders API written (she ran 0015-0019); shop UI checkout and the admin orders screens (list, details, status change + tracking code) are done; payment gateway postponed by her (2026-10-25).

## Session log
### 2026-11-06 — Discount link `/cart?code=` (web session, branch `claude/focused-euler-oqo92a`, API + shop UI repos)
- She ran 0038 and said "start the next one". Claude chose the link (open idea of task 34) and NOT customer blocking (still waiting for her OK on the rules). Did (shop UI only, no SQL, no API change): `/cart?code=WELCOME20` puts the code in the code box; a logged-in person gets it applied at once (as soon as the cart has books); a guest presses "اعمال", goes to login with `returnUrl=/cart?code=...` and gets it applied after login.
- Verified: `npm run build` ok, Playwright with a mocked API (logged in: chip shown, one CheckCode call with the cart price; guest: box prefilled, no call, login link keeps the code). NOT verified: real API.
### 2026-11-05 (3) — Sales by genre and author (web session, branch `claude/focused-euler-oqo92a`, API + admin repos)
- She ran 0036/0037 and said "start the next one". Claude chose genre / author sales over customer blocking (blocking touches login + orders, to be agreed with her first). Did: script `0038_reports_sales_breakdown.sql` (`Reports_SalesBreakdown`: 2 result sets, best genres and authors, at most 20 each, by price of the books); admin API `GET Reports/GetSalesBreakdown` (period rules moved into a private `ReadPeriod` shared with `GetSalesReport`), `ReportPeriodModel`, `SalesBreakdownOutputModel`, `GenreSalesOutputModel`, `AuthorSalesOutputModel`; admin UI `/reports`: two tables "پرفروش‌ترین ژانرها / نویسندگان" with a note that the amount is the books only.
- Verified: `dotnet build` 0 warnings, `npm run build` ok, Playwright with a mocked API (tables, author link, quiet failure = cards hidden, no toast). NOT verified: 0038 never run.
### 2026-11-05 (2) — Internal note on a customer (web session, branch `claude/focused-euler-oqo92a`, API + admin repos)
- She said "start the next one" (she ran nothing new). Claude chose customer notes (open idea of task 33). Did: script `0037_customer_note.sql` (`Users.AdminNote` NVARCHAR(500), `Customers_SetNote` (customers only), `Customers_GetById` redefined + `AdminNote`); admin API `CustomersController.SetCustomerNote`, `CustomersRepository.SetNoteAsync`, `SetCustomerNoteRequestModel`, `CustomerOutputModel.AdminNote`; admin UI customer page: "یادداشت داخلی" card (same behaviour as the order note).
- Verified: `dotnet build` 0 warnings, `npm run build` ok, Playwright with a mocked API (prefilled, save disabled until a change, trimmed text sent, disabled after save). NOT verified: 0037 never run.
### 2026-11-05 — Report comparison with the previous period (web session, branch `claude/focused-euler-oqo92a`, API + admin UI repos)
- She said "start the next one" (nothing to run). Claude chose the comparison (open idea of task 32). Did (admin UI only, no SQL, no API change): `/reports` asks the same report again for the period right before (same number of days) and shows ▲/▼ percent under revenue, orders, average order and books sold; the period text is shown above the cards. `utils/period-compare.ts`.
- Verified: `npm run build` ok, Playwright with a mocked API (30 days 1405/07/12..08/11 -> previous 06/13..07/11; 7 days -> 07/28..08/04; deltas right; a failing previous call = no deltas, no error toast). NOT verified against a real database.
### 2026-11-04 (4) — Excel export for reports and customers (web session, branch `claude/focused-euler-oqo92a`, API + admin UI repos)
- She ran 0036 and said "start the next one" (nothing new to run). Did (admin UI only, no SQL, no API change): "خروجی اکسل" on `/customers` (current search + sort, all pages, max 5000 -> `customers.csv`), on `/reports` for the days with sales (`sales-<from>-<to>.csv`) and for the best-selling books (`top-books.csv`); same `utils/csv-download.ts`.
- Verified: `npm run build` ok, Playwright with a mocked API (75 customers = 2 calls, 76 lines; report files with Jalali days; quotes doubled). NOT verified: real Excel.
