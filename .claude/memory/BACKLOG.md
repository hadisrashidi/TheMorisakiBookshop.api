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
12. Refresh tokens / revoke a stolen long "remember me" token (30 days) — with task 25. Password-login lockout per account DONE 2026-10-26 (script 0022). Still open: the SAME lockout in the admin API login (separate repo, it needs `Users_RegisterFailedLogin` / `Users_ClearFailedLogins` from 0022), and a per-IP rate limit (needs the real proxy setup, task 25).
13. Profile: name + birthdate are on the API (2026-10-26); only the avatar photo (data URL in UI localStorage) is left — needs an upload design (decide with her).
14. Admin promotion is a hand-run `EXEC dbo.Users_SetRole`; build an admin screen/endpoint only if needed (phase 5).

### Phase 3 — Cart, orders, stock
(done: orders, addresses, server cart 2026-10-26)

### Phase 4 — Payment and shipping
18. Payment gateway (Iranian, e.g. Zarinpal or IDPay — she checks the production requirements: domain, enamad). Flow: create payment → redirect → verify callback → mark order paid. Never trust the browser for "paid".
19. Shipping methods and prices (order statuses + tracking code are DONE 2026-10-25, script 0019).
20. Stock release for unpaid orders (timeout rule). WAIT for the payment gateway (task 18): until then "Paid" is set by hand in the admin, so a timer would cancel orders before she confirms them (decided 2026-10-26).

### Phase 5 — Admin (required before public launch)
22. Admin endpoints: books, authors, stock, orders (list, details, status + tracking code) are DONE in the SEPARATE repo `TheMorisakiBookshop.admin.api`. Still: refund / return handling after delivery (business rule, task 26).
23. Admin UI panel: books, authors, stock, orders (list, details, status buttons) DONE in `TheMorisakiBookshop.admin.ui`.

### Phase 6 — Ready to sell
24. Final header/footer, legal pages (terms, privacy, returns, shipping policy, contact), SEO basics, error pages.
25. Security + deployment pass: HTTPS, CORS for the real domain, secrets outside the repo (remove the local `sa` password from `appsettings.json` — see DECISIONS 2026-10-11), rate limiting on OTP/login, backups of the database, and the uploads folder (`Uploads:RootPath`, shared by the shop API and the admin API) on a persistent disk/volume + backups (a redeploy would delete uploaded covers).
26. Business items (not code, she owns them): return/refund policy, packaging standard for books, delivery-time promise, enamad/trust symbol, who handles customer support.

## SQL to run
- (none) She ran 0010-0021 (0021 on 2026-10-26). To run: 0022 + 0023 (see below).
- `Database/Migrations/0023_users_birthdate.sql` — `Users.Birthdate`, user read procedures redefined (keep lockout columns), new `Users_SetProfile`. Run after 0022. Needed by `Auth/UpdateProfile` (it now calls `Users_SetProfile`, so run it before using the profile page).
- `Database/Migrations/0022_login_lockout.sql` — columns `Users.FailedLoginCount/LockedUntil`, `Users_GetByEmail` (redefined), `Users_RegisterFailedLogin`, `Users_ClearFailedLogins`, `Users_ResetPassword` (redefined). Run after 0021 (she ran 0021, 2026-10-26). Needed by `Auth/LoginWithPassword`.

## For the UI repo
- (DONE in API + UI 2026-10-26) User objects carry `birthdate` (Jalali text `1372/05/12` or null). `POST Auth/UpdateProfile { name (2-100), birthdate ("" or yyyy/MM/dd) }` -> `data = user`. ALWAYS send both fields: an empty `birthdate` clears it. Needs script 0023.
- (DONE in API + UI 2026-10-26) Cart contract, answers the envelope, all need the token:
  - `GET Cart/GetMyCart` -> `data = [ { id (bookId), title, image, price, oldPrice (null = none), stock, quantity } ]`, in the order added; hidden books are left out; price/stock are always current.
  - `POST Cart/SetQuantity { bookId, quantity (0-20) }` -> `isSuccess`; quantity 0 removes the book; `false` + Persian message when the book is missing/hidden. The UI checks stock itself when adding (`addCheckedToCart`); the API checks again at order time.
  - `POST Cart/MergeCart { lines: [{ bookId, quantity }] }` -> `isSuccess`. Called once right after login with the guest cart: same book in both = quantities added (max 20); hidden/missing books skipped.
  - `POST Cart/ClearCart` -> `isSuccess` (after a successful order).
- (DONE in API + UI 2026-10-26) Addresses contract, answers the envelope, all need the token (401 otherwise):
  - `GET Addresses/GetMyAddresses` -> `data = [ { id, title, recipient, phone, city, fullAddress, postalCode, isDefault } ]`, default first.
  - `POST Addresses/AddAddress { title, recipient, phone ("" or 09xxxxxxxxx), city, fullAddress, postalCode ("" or 10 digits), isDefault }` -> `data = id`. The first address of a user is always the default.
  - `POST Addresses/UpdateAddress?id` (same body), `POST Addresses/DeleteAddress?id`, `POST Addresses/SetDefaultAddress?id` -> `isSuccess`; `false` + Persian message when the id is not found or belongs to another user. Deleting the default makes the oldest remaining one the default.
- (DONE in API + UI 2026-10-21) Orders contract, answers the envelope, both need the token (401 otherwise):
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
