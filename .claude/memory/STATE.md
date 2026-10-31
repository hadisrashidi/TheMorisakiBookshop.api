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
### 2026-10-31 (2) — Shipping methods (web session, branch `claude/focused-euler-oqo92a`, API + UI + admin API + admin UI)
- Her input: she liked the structure of a coffee shop's shipping text (Tehran vs other cities, free above an amount, fixed fee, cut-off time); she does NOT know her real methods/prices/times yet ("put reasonable temporary ones, help me decide later"); books are expensive (2-3 books > 800,000 toman) so free shipping from 2,000,000 toman (her OK for the start).
- Did: script `0027_shipping_methods.sql` (`ShippingMethods` table + 3 PLACEHOLDER rows, `Orders.ShippingMethodName`, `ShippingMethods_GetActive/GetAll/Save`, new `Orders_Place` with shipping, `Orders_GetByUserId/GetById` return the method name); C#: `ShippingController.GetShippingMethods`, `ShippingMethodsRepository`, `ShippingMethodOutputModel`, `PlaceOrderRequestModel.City/ShippingMethodId`, new problem `ShippingMethodInvalid`. Admin API `ShippingController` (`GetAllShippingMethods`, `SaveShippingMethod`). Shop UI: method choice in the cart summary, `/shipping` page from the database. Admin UI: `/shipping` page (list, edit, on/off).
- Verified: `dotnet build` 0 warnings (shop + admin API), `npm run build` ok (both UIs), Playwright with mocked APIs (cart options + free at 2.7M + chosen method, `/shipping` cards, admin edit sends the right body). NOT verified: 0027 never run (no SQL Server here), no real order with shipping.
- Next: she runs 0026 + 0027, tests an order. She still owes the real shipping facts (BACKLOG "Questions for her").
### 2026-10-31 — Review of what is missing + advanced order filters (web session, branch `claude/focused-euler-oqo92a`, ALL FOUR repos attached)
- Her request: shop is not complete, no admin reference; she named example shops (oketab, کتاب ملت, کتاب مینویی; they could not be opened/found from the VM), asked for advanced filters (books, authors, above all orders), reports, order tracking for customers, a shipping-methods page, several payment methods; "review, prioritise and do it". Roadmap written to BACKLOG "Phase 7" (my order). Payment: she said NOT to bring up the gateway unless she does.
- Did first (task 28): script `0026_orders_search_filters.sql` (`Orders_Search`: date range, total range, sort, third result set = orders per status); admin API `OrderSearchRequestModel` + `Orders/SearchOrders` (Jalali dates converted in C#); admin UI status tabs with counts + advanced filter panel + quick ranges.
- Verified: `dotnet build` 0 warnings (admin API), `npm run build` ok, Playwright with a mocked API (tabs, counts, Persian digits, quick range, validation message). NOT verified: 0026 never run (no SQL Server here).
- Next: she runs 0026 and tries the filters; then task 29.
### 2026-10-27 (2) — UI polish start (web session, same branch, UI only)
- She ran 0022 + 0023 (and 0024). Asked to start UI polish; no API change. Done in the UI repo: header genre links, account menu, footer links, 404 page, page titles, DRAFT legal pages (details in the UI STATE). Footer contact data is sample data.
### 2026-10-27 — Write a review (web session, branch `claude/focused-euler-oqo92a`, API + UI)
- Her answers: any logged-in user may review, shown at once (she deletes if needed), stars + text. Chosen by me (told her): one review per person per book, saving again replaces it; reviewer name copied from the account; date = Jalali text made in C#. Did: `0024_reviews_write.sql`, `SaveReviewRequestModel`, `ReviewsRepository.GetByUserAndBookAsync/SaveAsync`, `ReviewsController.GetMyReview/SaveReview`. UI: review form in the reviews tab of the book page. Contract in "For the UI repo".
- Verified: `dotnet build` 0 warnings, `npm run build` ok. NOT verified: 0024 never run, no browser test.
- She ran 0024 (2026-10-27). Next: she tests (write, edit, logged out). Admin delete button needs the admin repos (BACKLOG 27).
### 2026-10-26 (4) — Profile birthdate on the server (web session, same branch, API + UI)
- Order chosen by me (she said so): lockout (done above) -> profile -> reviews -> UI polish. Did: `0023_users_birthdate.sql`, `UserModel` / `UserOutputModel` / `JwtTokenService.ToOutputModel` (+ `Birthdate`), `UpdateProfileRequestModel.Birthdate`, `UsersRepository.SetProfileAsync`, `AuthController.UpdateProfile`. UI: `UserModel.birthdate`, `UpdateProfileRequestModel.birthdate`, profile page saves name + birthdate, login moves a local birthdate to an account without one.
- Verified: `dotnet build` 0 warnings, `npm run build` ok. NOT verified: 0022 and 0023 never run, no browser test.
- Next: she runs 0022 + 0023. Avatar stays in the browser.
