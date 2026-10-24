# Backlog
<!-- open work only. Finished items go to archive/done.md with the date. Top = next. -->
<!-- Roadmap agreed 2026-10-07: phases 0 → 6. Phase 5 (admin) must be done before any public launch. -->
<!-- This file is the master roadmap for both repos; UI-only tasks live in the UI repo BACKLOG. -->

## Open tasks

### Phase 0 — Foundation
7. UI side of phase 0 (UI repo): `ApiHelperService` base pieces + align API URL → see UI BACKLOG tasks 1-2.

### Phase 1 — Good catalog

### Phase 2 — Accounts
11. Real SMS provider for OTP (code is only logged now, `Security/SmsSender.cs`). Pick one (Kavenegar recommended) and put its API key in env vars, not in the repo. Until then `SmsSender` MUST NOT run in production (codes in logs).
12. Refresh tokens / revoke a stolen long "remember me" token (30 days) + rate limit for password login (`LoginWithPassword` has no lockout / throttling yet) — with task 25.
13. Profile/addresses: tables `Addresses`; endpoints replace UI localStorage (`Users` already exists).
14. Admin promotion is a hand-run `EXEC dbo.Users_SetRole`; build an admin screen/endpoint only if needed (phase 5).

### Phase 3 — Cart, orders, stock
15. Cart stored per user in DB; guest cart stays in UI localStorage and is merged into the server cart right after login (decided 2026-10-07).

### Phase 4 — Payment and shipping
18. Payment gateway (Iranian, e.g. Zarinpal or IDPay — she checks the production requirements: domain, enamad). Flow: create payment → redirect → verify callback → mark order paid. Never trust the browser for "paid".
19. Order statuses (pending payment, paid, packed, shipped, delivered, cancelled) + shipping methods and prices + tracking code field.
20. Stock release for unpaid/cancelled orders (timeout rule) — decide with her.

### Phase 5 — Admin (required before public launch)
22. Admin endpoints: books, authors, stock are DONE (2026-10-19) in the SEPARATE repo `TheMorisakiBookshop.admin.api`. Still: orders (status change, tracking code) — there, after phase 3.
23. Admin UI panel: books + authors + stock DONE (2026-10-19) in `TheMorisakiBookshop.admin.ui`. Still: orders screens.

### Phase 6 — Ready to sell
24. Final header/footer, legal pages (terms, privacy, returns, shipping policy, contact), SEO basics, error pages.
25. Security + deployment pass: HTTPS, CORS for the real domain, secrets outside the repo (remove the local `sa` password from `appsettings.json` — see DECISIONS 2026-10-11), rate limiting on OTP/login, backups of the database, and the uploads folder (`Uploads:RootPath`, shared by the shop API and the admin API) on a persistent disk/volume + backups (a redeploy would delete uploaded covers).
26. Business items (not code, she owns them): return/refund policy, packaging standard for books, delivery-time promise, enamad/trust symbol, who handles customer support.

## SQL to run
- `Database/Migrations/0017_orders_admin_procedures.sql` — `dbo.Orders_Search`, `dbo.Orders_GetById` (read only, used by the admin API orders screens). Run after 0016.
- `Database/Migrations/0015_create_orders_tables.sql` — `dbo.Orders`, `dbo.OrderLines`. Run after 0014. Before using `Orders/*`.
- `Database/Migrations/0016_orders_procedures.sql` — `dbo.Orders_Place`, `dbo.Orders_GetByUserId`. Run after 0015.
- `Database/Migrations/0013_books_is_active.sql` — adds `Books.IsActive`, updates all shop book procedures, new `Books_SetStock` / `Books_SetActive`, drops `Books_Delete`. Run after 0012 and BEFORE using the new API (every book read selects `IsActive`). Also needed by the admin API.
- `Database/Migrations/0014_authors_management_procedures.sql` — `dbo.Authors_Insert`, `dbo.Authors_Update` (used by the admin API). Run after 0013.
- `Database/Migrations/0012_users_name.sql` — adds `Users.Name`, updates 3 read procedures, new `dbo.Users_SetName`. Run after 0011 and BEFORE using the new API (Register/GetById need the column).
- `Database/Migrations/0010_create_auth_tables.sql` — `Users`, `OtpCodes`. Run before 0011.
- `Database/Migrations/0011_auth_procedures.sql` — OTP + user procedures. After it, log in once through the API, then make yourself admin: `EXEC dbo.Users_SetRole @Mobile = N'09...', @Role = N'Admin';`.

## For the UI repo
- (DONE in API 2026-10-21, UI not yet = UI BACKLOG task 6) Orders contract, answers the envelope, both need the token (401 otherwise):
  - `POST Orders/PlaceOrder { recipientName, recipientMobile (09xxxxxxxxx), address, postalCode ("" or 10 digits), lines: [{ bookId, quantity (1-20) }] }` -> `data = orderId` (int). `isSuccess: false` + Persian message when a book is hidden/missing or stock is not enough (nothing is saved, no stock taken). Prices come from the database, the UI sends NO price. Order status starts `PendingPayment`.
  - `GET Orders/GetMyOrders` -> `data = [ { id, status, subtotal, shippingCost, total, recipientName, recipientMobile, address, postalCode, trackingCode, createdAt (ISO, UTC), lines: [ { bookId, title, image, unitPrice, quantity } ] } ]`, newest first. `status` is one of `PendingPayment | Paid | Packed | Shipped | Delivered | Cancelled` (UI maps to Persian). The old local `Order` model (string id, Jalali date) must be replaced; `createdAt` -> Jalali in the UI.
  - Checkout must collect the recipient (name, mobile, address): the UI addresses page is still localStorage, pick the default address there for now.
- (2026-10-19) The admin contract (books/authors management, image upload, admin login) moved to the repo `TheMorisakiBookshop.admin.api` (its BACKLOG → "For the admin UI repo"). Shop UI needs nothing from it except: book objects may carry `isActive` (always true in shop answers) and images may be `/uploads/...` paths (pipe `apiImage`).
- (DONE in API + UI 2026-10-13) Auth contract, all answer the envelope. Send `Authorization: Bearer <token>` on logged-in calls; 401 = not logged in, 403 = not Admin (both envelope).
  - `POST Auth/RequestOtp` `{ mobile }` (`09xxxxxxxxx`) → `isSuccess`; `false` + message when asked again within 1 min or >5 per hour. Code = 6 digits, valid 2 min. No SMS yet: the code is in the API console log.
  - `POST Auth/VerifyOtp` `{ mobile, code }` → `data = { token, expiresAt, user: { id, mobile, email, hasPassword, role } }`. New mobile = account created. 5 wrong codes lock that code.
  - (DONE 2026-10-13) `VerifyOtp`, `LoginWithPassword` and `Register` also take `rememberMe` (bool, default false): true = token valid 30 days, else 1 hour.
  - (DONE 2026-10-13) User objects carry `name` (string or null). `POST Auth/UpdateProfile` `{ name }` (needs token) → `data = user`.
  - `POST Auth/Register` `{ mobile, code, name, email, password (min 8) }` (code from `RequestOtp`) → same `data` as `VerifyOtp`. `isSuccess: false` when the email belongs to another mobile.
  - `POST Auth/LoginWithPassword` `{ email, password }` → same `data`.
  - `POST Auth/SetCredentials` `{ email, password (min 8) }` (needs token) → adds/changes email+password.
  - `POST Auth/ResetPassword` `{ mobile, code, newPassword }` (code from `RequestOtp`; only accounts that already have a password) → `isSuccess`; user then logs in normally.
  - `GET Auth/GetMe` (needs token) → `data = user`. Token lifetime 60 min (`Jwt:ExpiresMinutes`), no refresh token yet.
- (DONE in API + UI 2026-10-12) `GET Books/GetSearchFilters` → `data = { minPrice, maxPrice, genres[], languages[] }`.
- (DONE in API + UI 2026-10-12) `GET Books/SearchBooks` returns `data = { items, totalCount, page, pageSize }` instead of a plain list. New query params: `page` (default 1), `pageSize` (default 9, clamped 1-50 in SQL), `authorId`, `minPrice`, `maxPrice`. Still: `q`, `genres`, `languages`, `inStockOnly`, `sort`.
<!-- API contract changes the Angular app must follow. She copies these into the UI session. -->
- (DONE in API 2026-10-07) Every response is wrapped: `{ isSuccess, data, message, errors }`. Not-found is HTTP 200 with `isSuccess: false`. Validation errors = HTTP 400 with the same shape; server errors = 500 with the same shape. Create/update/delete in `BooksManagement` also answer 200 + envelope (create no longer returns 201 + Location; delete no longer 204).
- UI `public/env/env.js` points to `https://localhost:44388/api/`, but `Properties/launchSettings.json` uses `https://localhost:7106` / `http://localhost:5074` — align one of them.
- (DONE in API 2026-10-12) Book responses carry `stock` (number) and `inStock` (computed from `Stock > 0`); create/update book requests send `stock` instead of `inStock` (no `InStock` column); `Price` / `OldPrice` become JSON numbers (`DECIMAL(18,0)`), not strings.
- (planned, phases 2-4) New endpoint groups will appear: auth (OTP, email+password), profile/addresses, cart, orders, payment. Contracts are written here when each task is designed.

- (DONE in API 2026-10-12) `GET Books/SearchBooks`: `inStockOnly` is a plain bool; `genres` / `languages` repeat in the query (`?genres=a&genres=b`). Book `specs` still `[{ label, value }]`. `Price`/`OldPrice` JSON numbers, `oldPrice` is `null` (not "") when there is no discount. Review `date` stays Jalali text.

## Questions for her
- Payment gateway choice and its production requirements (task 18).
- SMS provider for OTP (task 11).
