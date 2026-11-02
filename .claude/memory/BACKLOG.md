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

### Phase 2b — Reviews
27. DONE 2026-11-02: the admin lists and deletes reviews (script 0031, admin API `Reviews/*`, admin UI `/reviews`). Open ideas: hide instead of delete, "report this review" button in the shop, ban a user from reviewing.

### Phase 7 — Review of what is missing (2026-10-31, order chosen by Claude; she said "review, prioritise, do it")
28. DONE 2026-10-31: orders list advanced filters + status tabs with counts (script 0026, admin API, admin UI).
29. DONE 2026-11-01: books filters (stock tabs, author, genre + language multi-select, visibility, price range, sort) + author-name search (script 0028), authors genre filter. Not done: author filter `has books`, counts on the stock tabs.
30. DONE 2026-11-02 (script 0029): status timeline, tracking code + copy + post-site link, customer cancel while PendingPayment. Open: check the post tracking URL (is `?id=` accepted so the code can be pre-filled?), links for other carriers (chapar) when she picks them, SMS on status change (needs task 11).
31. DONE 2026-10-31 with PLACEHOLDER data (script 0027, shop cart choice, `/shipping` page, admin page). Still open: her real methods, prices, free-above amount, cut-off time and delivery texts (see Questions for her); optional later: weight/city based prices, pickup address.
32. DONE 2026-11-02 (script 0030): sales summary, chart per day / month, best-selling books, low stock. Report export to CSV DONE 2026-11-04 (days with sales + best-selling books). Comparison with the previous period DONE 2026-11-05. Sales by genre and author DONE 2026-11-05 (script 0038). Sales by city DONE 2026-11-07 (script 0041, `Orders.City`). Open ideas: payment-date based revenue (needs the order history of script 0029 for old orders), customers report (task 33).
33. DONE 2026-11-03: customers list + customer page, internal note on an order (script 0034). Order list row actions (cancel, copy tracking code) DONE 2026-11-04 (script 0036). Orders export to CSV/Excel DONE 2026-11-04 (admin UI only). Customers export DONE 2026-11-04. Customer note DONE 2026-11-05 (script 0037). Blocking a customer DONE 2026-11-06 (script 0039). Blocked filter in the customers list DONE 2026-11-06 (script 0040). Open ideas: block by mobile before sign-up, mail / SMS to the customer. (Invoice printing DONE 2026-11-03: admin only; open ideas: a customer can print / download her invoice in the shop, one invoice for several orders, a shipping label with the address and a barcode, an invoice number separate from the order number, tax / VAT lines if she needs them.)
34. Shop extras to consider: (discount codes DONE 2026-11-03, script 0032; open ideas: auto-apply link `/cart?code=` DONE 2026-11-06, codes for first order only, show discounts in the reports), best sellers block DONE 2026-11-04 (script 0035), "notify me when available", gift wrap.
35. Several payment methods (she wants more than one gateway: e.g. card-to-card with receipt check, cash on delivery) — belongs to task 18; not discussed until she raises it.

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
24. Launch polish: DONE in the UI 2026-10-27 as drafts (404, titles, legal pages, footer links); real texts/contact data wait for task 26 and her real details.
25. Security + deployment pass: HTTPS, CORS for the real domain, secrets outside the repo (remove the local `sa` password from `appsettings.json` — see DECISIONS 2026-10-11), rate limiting on OTP/login, backups of the database, and the uploads folder (`Uploads:RootPath`, shared by the shop API and the admin API) on a persistent disk/volume + backups (a redeploy would delete uploaded covers).
26. Business items (not code, she owns them; the draft legal pages and FAQ currently say: returns within 7 days, shipping in 2-5 working days — placeholders): return/refund policy, packaging standard for books, delivery-time promise, enamad/trust symbol, who handles customer support.

## SQL to run
- `Database/Migrations/0041_orders_city_and_city_report.sql` — `Orders.City` (+ backfill of old orders from their address text), `Orders_Place` redefined (saves the city), `Reports_SalesByCity`. Run after 0040 (needs 0032 + 0030). **Test one new order after it** (the shop checkout uses the new `Orders_Place`). Needed by the admin API `Reports/GetSalesByCity` (without it the city card is simply missing).
- `Database/Migrations/0040_customers_search_blocked_filter.sql` — `Customers_Search` redefined (+ optional `@Status`). Run after 0039. Old calls keep working; the admin filter only has an effect after it.
- `Database/Migrations/0039_customer_blocking.sql` — `Users.IsBlocked/BlockReason/BlockedAt`, `Customers_SetBlocked`, `Users_IsBlocked`, user read procedures + `Customers_Search/GetById` redefined. Run after 0038 (needs 0037). **Run it BEFORE restarting the shop API**: the shop API now calls `Users_IsBlocked` on every request that carries a login token (without the script every logged-in call fails). The admin API customer pages need it too.
- `Database/Migrations/0038_reports_sales_breakdown.sql` — `Reports_SalesBreakdown` (new procedure only). Run after 0037 (needs 0030). Needed by the admin API `Reports/GetSalesBreakdown` (without it the two new report tables are simply missing, no error).
- `Database/Migrations/0037_customer_note.sql` — `Users.AdminNote`, `Customers_SetNote`, `Customers_GetById` redefined (+ `AdminNote`). Run after 0036 (needs 0034). Needed by the admin API customer page (the reader expects the new column).
- `Database/Migrations/0036_orders_search_tracking_code.sql` — `Orders_Search` redefined (+ `TrackingCode` in the page rows). Run after 0035. Needed by the admin orders list copy button (without it the button simply does not show).
- `Database/Migrations/0035_books_best_sellers.sql` — `Books_GetBestSellers` (new procedure only). Run after 0034 (needs 0016). Needed by `GET Books/GetBestSellers` (the home page block; without it that call fails and the block stays hidden).
- `Database/Migrations/0034_customers_and_order_note.sql` — `Orders.AdminNote`, `Orders_SetNote`, `Customers_Search`, `Customers_GetById`, `Orders_GetById` redefined (+ `AdminNote`, `UserId`). Run after 0033 (needs 0032). The admin API order details need it (the reader expects the new columns).
- `Database/Migrations/0033_shop_settings.sql` — table `ShopSettings` (one row, seeded with the old footer sample data), `ShopSettings_Get/Save`. Run after 0032. Needed by the admin API `Settings/*`, the invoice and the shop footer (the footer shows its fallback until it runs).
- `Database/Migrations/0032_discount_codes.sql` — tables `DiscountCodes` + `DiscountCodeUses`, `Orders.DiscountCode/DiscountAmount`, `DiscountCodes_Check/GetAll/Save`, `Orders_Place` / `Orders_GetByUserId` / `Orders_GetById` redefined. Run after 0031 (needs 0029). The shop API + admin API + both UIs of this session need it (deploy together).
- `Database/Migrations/0031_reviews_admin_search.sql` — `Reviews_Search` (new procedure only). Run after 0030 (needs 0024). Needed by the admin API `Reviews/SearchReviews`.
- `Database/Migrations/0030_reports.sql` — `Reports_Sales`, `Reports_LowStock` (new procedures only). Run after 0029 (needs 0016). Needed by the admin API `Reports/*`.
- `Database/Migrations/0029_order_status_history.sql` — `OrderStatusHistory` table, `Orders_Place` / `Orders_SetStatus` redefined (history rows, `@OnlyIfStatus`), new `Orders_CancelMine`, `Orders_GetByUserId` / `Orders_GetById` redefined (history result set). Run after 0028. The shop API + admin API of this session need it (their order readers expect the extra result set).
- `Database/Migrations/0028_books_search_author_and_admin_filters.sql` — `Books_Search` redefined (search text also matches the author name, `@StockStatus`, `@Visibility`, two more sorts). Run after 0027. Old calls (shop UI) keep working.
- `Database/Migrations/0027_shipping_methods.sql` — table `ShippingMethods` (3 placeholder rows), `Orders.ShippingMethodName`, shipping procedures, new `Orders_Place` (NEEDS the UI of this session: it requires a shipping method), `Orders_GetByUserId` / `Orders_GetById` redefined. Run after 0026 (needs 0016 + 0017). Deploy the shop API + UI together with it.
- (none) She ran 0010-0040 (2026-11-07). To run: 0041 (above).
- `Database/Migrations/0026_orders_search_filters.sql` — `Orders_Search` redefined (date range, total range, sort, third result set with orders per status). Run after 0019. Needed by the admin API `Orders/SearchOrders` (old calls still work).

## For the UI repo
- (DONE in API + UI 2026-11-04, needs script 0035) `GET Books/GetBestSellers` (public) -> `data = [ book ]` (same shape as `GetNewBooks`, max 8, most copies sold first; empty list when nothing sold yet).
- (DONE in API + UI 2026-11-03, needs script 0033) `GET Settings/GetShopInfo` (public) -> `data = { shopName, phone, email, address, instagramUrl, telegramUrl, whatsappUrl }` (any can be ""); the footer shows them (an empty link hides its icon). Edited in the admin panel (`/settings`).
- (DONE in API + UI 2026-11-03, needs script 0032) Discount codes: `POST Discounts/CheckCode { code, subtotal }` (token; subtotal = price of the books in the cart, preview only) -> `data = { code (capital letters), discountAmount }`; `isSuccess: false` + Persian message when the code does not exist / is off / not started / expired / minimum price not reached / usage limit / per-customer limit. `POST Orders/PlaceOrder` takes an optional `discountCode` (checked AGAIN inside the order transaction; a refused code = no order, Persian message, stock untouched). Orders of `GetMyOrders` carry `discountCode` ("" = none) and `discountAmount`; `total = subtotal - discountAmount + shippingCost`. The discount takes off the books only; shipping is free by the books' price BEFORE the discount.
- (DONE in API + UI 2026-11-02, needs script 0029) Order tracking: every order of `GET Orders/GetMyOrders` carries `history: [ { orderId, status, changedAt (ISO UTC) } ]`, oldest first (old orders have only the first row; the UI shows the steps from `status` too). `POST Orders/CancelMyOrder?id` (token) -> `isSuccess`; `false` + Persian message when the order is not hers (not found) or no longer `PendingPayment`; cancelling gives the stock back.
- (DONE in API + UI 2026-10-31, needs script 0027) Shipping: `GET Shipping/GetShippingMethods?subtotal&city` (public) -> `data = [ { id, name, price, freeAbove (null = never), cost (what THIS cart pays: 0 when subtotal >= freeAbove), deliveryText, tehranOnly } ]`; with `city` (Persian/Arabic ی ک are the same) Tehran-only methods are left out for other cities; without `subtotal`/`city` = the information list. `POST Orders/PlaceOrder` now ALSO needs `city` and `shippingMethodId` (API refuses with a Persian message when the method is off or not allowed for the city); the cost is worked out in SQL from database prices; `GET Orders/GetMyOrders` orders carry `shippingMethodName` (empty for old orders).
- (DONE in API + UI 2026-10-27) Reviews, both need the token: `GET Reviews/GetMyReview?bookId` -> `data = review` (same shape as the list items) or `null` when the person has none; `POST Reviews/SaveReview { bookId, rating (1-5), text (3-2000) }` -> `isSuccess`; creates the review or replaces the person's old one for that book; `false` + Persian message when the book is missing/hidden. The list endpoints (`GetByBookId`, `GetByAuthorId`) are unchanged and public; a new review appears there at once. Needs script 0024.
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
- Shipping (she will think about it and wants GUIDANCE; placeholders are in the database, editable in the admin `/shipping`): which methods she really offers (post pishtaz / chapar / Tehran courier / pickup), real prices (get quotes from the carrier for a typical book parcel), free-above amount (placeholder 2,000,000 toman), order cut-off time and delivery times (placeholder: 12:00, 2-5 working days post, 1-2 days Tehran courier). Help her decide when she asks.
- Payment gateway choice and its production requirements (task 18).
- SMS provider for OTP (task 11).
