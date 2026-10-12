# Backlog
<!-- open work only. Finished items go to archive/done.md with the date. Top = next. -->
<!-- Roadmap agreed 2026-10-07: phases 0 → 6. Phase 5 (admin) must be done before any public launch. -->
<!-- This file is the master roadmap for both repos; UI-only tasks live in the UI repo BACKLOG. -->

## Open tasks

### Phase 0 — Foundation
5. Delete `Data/*.json` and the `<None Include="Data\**\*.json" ...>` item in the csproj — she confirmed the DB-backed API works (2026-10-12) — ask before deleting.
7. UI side of phase 0 (UI repo): `ApiHelperService` base pieces + align API URL → see UI BACKLOG tasks 1-2.

### Phase 1 — Good catalog
- Remaining: facets endpoint (distinct genres/languages, min/max price) so the UI filters stop using hand-typed lists — task 8b.

### Phase 2 — Accounts
11. Login with **mobile + OTP (SMS)** first. Decide with her before coding: SMS provider, OTP rules (length, expiry, resend limit, rate limit), JWT lifetime, new NuGet packages (JWT bearer).
12. Optional second login: **email + password** (password hashing package — ask first). Built after 11 works; same JWT after either login.
13. Tables + procedures: `Users`, `Addresses`; endpoints for profile and addresses (replaces UI localStorage).
14. Roles: `Customer`, `Admin` (needed by phase 5).

### Phase 3 — Cart, orders, stock
15. Cart stored per user in DB; guest cart stays in UI localStorage and is merged into the server cart right after login (decided 2026-10-07).
16. Place order = ONE stored procedure with a transaction: checks stock, decreases stock, creates `Orders` + `OrderLines`. Price of every line is copied into the order at purchase time (later price changes must not change old orders). Not enough stock = `isSuccess: false` with a clear message.
17. Orders list/details endpoints for the logged-in user (UI "orders" page).

### Phase 4 — Payment and shipping
18. Payment gateway (Iranian, e.g. Zarinpal or IDPay — she checks the production requirements: domain, enamad). Flow: create payment → redirect → verify callback → mark order paid. Never trust the browser for "paid".
19. Order statuses (pending payment, paid, packed, shipped, delivered, cancelled) + shipping methods and prices + tracking code field.
20. Stock release for unpaid/cancelled orders (timeout rule) — decide with her.

### Phase 5 — Admin (required before public launch)
21. **Protect `BooksManagementController` with the Admin role** — today anyone can delete books or change prices. Highest priority of this phase; do it as soon as roles (14) exist.
22. Admin endpoints: manage books, authors, stock, orders (status change, tracking code).
23. Admin UI panel (UI repo).

### Phase 6 — Ready to sell
24. Final header/footer, legal pages (terms, privacy, returns, shipping policy, contact), SEO basics, error pages.
25. Security + deployment pass: HTTPS, CORS for the real domain, secrets outside the repo (remove the local `sa` password from `appsettings.json` — see DECISIONS 2026-10-11), rate limiting on OTP/login, backups of the database.
26. Business items (not code, she owns them): return/refund policy, packaging standard for books, delivery-time promise, enamad/trust symbol, who handles customer support.

## SQL to run
- `Database/Migrations/0008_books_search_paging.sql` — new `dbo.Books_Search` (author, price range, paging, total count). Run it BEFORE starting the API, otherwise search returns a 500.

## For the UI repo
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
