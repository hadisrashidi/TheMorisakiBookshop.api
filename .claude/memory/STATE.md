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
- Login lockout (2026-10-26, script 0022 NOT run yet): `AuthController.LoginWithPassword` + `UsersRepository.RegisterFailedLoginAsync/ClearFailedLoginsAsync`, columns `Users.FailedLoginCount/LockedUntil`.
- CI: `.github/workflows/build.yml` runs `dotnet build` on push/PR to main.

## Active work
- Phase 2 (accounts) done; phase 5 started in the separate admin repos (2026-10-19). She runs 0013 + 0014, then tests admin.ui. Still open in phase 5: orders admin (after phase 3). Real SMS provider still open (mock for now). Phase 3 started 2026-10-21: orders API written (she ran 0015-0019); shop UI checkout and the admin orders screens (list, details, status change + tracking code) are done; payment gateway postponed by her (2026-10-25).

## Session log
### 2026-10-26 (4) — Profile birthdate on the server (web session, same branch, API + UI)
- Order chosen by me (she said so): lockout (done above) -> profile -> reviews -> UI polish. Did: `0023_users_birthdate.sql`, `UserModel` / `UserOutputModel` / `JwtTokenService.ToOutputModel` (+ `Birthdate`), `UpdateProfileRequestModel.Birthdate`, `UsersRepository.SetProfileAsync`, `AuthController.UpdateProfile`. UI: `UserModel.birthdate`, `UpdateProfileRequestModel.birthdate`, profile page saves name + birthdate, login moves a local birthdate to an account without one.
- Verified: `dotnet build` 0 warnings, `npm run build` ok. NOT verified: 0022 and 0023 never run, no browser test.
- Next: she runs 0022 + 0023. Avatar stays in the browser.
### 2026-10-26 (3) — Password-login lockout (web session, same branch)
- She ran 0021. Asked her what next (options: lockout / profile / reviews / UI polish); she chose lockout, then said "do the rest in the order you think is right". Did: `0022_login_lockout.sql`, `UserModel` (+ `FailedLoginCount`, `LockedMinutesLeft`), `UsersRepository` (2 methods), `AuthController.LoginWithPassword` + `GetLockedMessage`. Contract unchanged (same envelope, new Persian message when locked).
- Verified: `dotnet build` 0 warnings. NOT verified: 0022 never run, no real wrong-password round trip.
- Next: she runs 0022 and tries 5 wrong passwords; admin API needs the same lockout (BACKLOG 12).
### 2026-10-26 (2) — Server cart (web session, same branch, API + UI)
- She ran 0020. Her ask: "next one". Told her task 20 (stock release timer) must wait for the payment gateway (manual "Paid" in admin), so did task 15. Script `0021_cart.sql`; `CartItemOutputModel`, `SetCartQuantityRequestModel`, `MergeCartRequestModel`, `CartRepository`, `CartController`, registered in `Program.cs`. UI: `CartApiService`, `CartService` (logged in = server cart, guest = localStorage, merge at login, empty on logout), 3 new models. Contract in "For the UI repo".
- Verified: `dotnet build` 0 warnings; app starts, `Cart/GetMyCart` and `Cart/ClearCart` answer the 401 envelope; `npm run build` ok. NOT verified: script 0021 never run, no browser test, no real round trip.
- Next: she runs 0021, tests: add as guest -> login (merge), change quantity, second browser, logout, order clears the cart.
### 2026-10-26 — Addresses on the server (web session, branch `claude/lucid-faraday-5ab9od`, API + UI)
- Her choice: start task 13 (addresses) after "next task" options. Did: script `0020_addresses.sql`; `AddressOutputModel`, `SaveAddressRequestModel`, `AddressesRepository`, `AddressesController`, registered in `Program.cs`. UI: `AddressesApiService`, `AddressesService` rewritten (server list in a signal, one-time upload of old localStorage addresses), addresses page async + `isSaving`, cart loads addresses before checkout; models `address.response.model.ts` / `save-address.request.model.ts` (old `address.model.ts` removed).
- Verified: `dotnet build` 0 warnings, `npm run build` ok. NOT verified: script 0020 never run (no SQL Server here), no browser test, no real round trip.
- Next: she runs 0020, tests addresses page + checkout.
### 2026-10-21 — Phase 3 start: orders API (web session, branch `claude/gifted-curie-7qha13`; admin repos attached but untouched)
- Her request: an orders section in the admin panel. Found: no orders exist (shop checkout is fake, localStorage) -> order of work: shop orders API, shop UI checkout, then admin list. She agreed with: cart stays in localStorage, status `PendingPayment` (DECISIONS 2026-10-21).
- Did: scripts `0015_create_orders_tables.sql`, `0016_orders_procedures.sql`; C#: `OrdersController`, `OrdersRepository`, `OrderOutputModel`, `OrderLineOutputModel`, `OrderPlacedModel`, `PlaceOrderRequestModel`, `OrderLineRequestModel`, `OrdersRepository` registered in `Program.cs`. Contract in "For the UI repo".
- Verified: `dotnet build` 0 warnings (installed .NET 8 SDK in the VM with apt); both endpoints answer the 401 envelope without a token. NOT verified: scripts 0015-0016 never run (no SQL Server here), no real order round trip.
- Follow-up (same day): she ran 0012-0016. UI checkout + orders page now call the API (UI repo, same branch). Wrote `0017_orders_admin_procedures.sql` (`Orders_Search` paged + filters, `Orders_GetById`) for the admin repos (`OrdersController` there: `SearchOrders`, `GetOrderById`, read only). Her request: "see the shop orders in the admin panel". NOT verified: 0017 never run, no real database round trip.
- She ran 0017 (OK, 2026-10-24). Her follow-up wishes: book titles in the admin orders table, stock check when adding to the cart, live admin list -> script `0018_orders_search_book_titles.sql` (`Orders_Search` + `BookTitles` via `STRING_AGG`, search matches a book title); the other two are UI/admin work. NOT verified: 0018 never run.
- She ran 0018 and tested book titles, the add-to-cart stock check and the live admin list: OK (2026-10-24).
- She ran 0019 (OK, 2026-10-26). Open: her image report (compare the two `Uploads folder` log lines), then payment (phase 4) or the next task she picks.
