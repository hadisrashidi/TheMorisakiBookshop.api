# Backlog
<!-- open work only. Finished items go to archive/done.md with the date. Top = next. -->
<!-- Roadmap agreed 2026-10-07: phases 0 → 6. Phase 5 (admin) must be done before any public launch. -->
<!-- This file is the master roadmap for both repos; UI-only tasks live in the UI repo BACKLOG. -->

## Open tasks

### Phase 0 — Foundation
1. Introduce the response envelope (skill `dotnet-simple` → "Response envelope"): add `Models/CustomActionResult.cs` + `Models/CustomActionResultOfT.cs`, validation + exception handler in `Program.cs`, wrap every action in all 4 controllers in `Ok(new CustomActionResult...)` (replace `NotFound`, `NoContent`, `CreatedAtAction`). Contract change → see "For the UI repo".
2. Add NuGet packages `Dapper` and `Microsoft.Data.SqlClient` (ask her first, explain what each does); add `ConnectionStrings:Bookshop` to `appsettings.Development.json` (Windows auth).
3. Migration: create tables `Authors`, `Books`, `BookSpecs`, `Reviews` (re-runnable) + seed them from `Data/*.json`, keeping the same Ids (UI routes use them).
   - Decide with her: price columns as `DECIMAL(12,0)` instead of the current strings ("185000") — C# `Price`/`OldPrice` would become `decimal`, and the UI must be told.
   - Add stock column (`Stock INT`) now so phase 3 does not need a table rework.
4. Migration: stored procedures for every current repository method (Books: GetAll, GetById, GetNewest, GetFeatured, GetRelated, GetSimilar, GetByAuthor, Search, Insert, Update, Delete; Authors; Reviews: GetByBookId, GetByAuthorId).
5. Replace `Json*Repository` + `I*Repository` with Dapper repositories (`BooksRepository`, `AuthorsRepository`, `ReviewsRepository`); register them in `Program.cs`; delete `Data/*.json` and the `<None Include="Data\**\*.json" ...>` item in the csproj only after she confirms the DB works.
6. Bring existing code to skill `dotnet-simple` naming (best done together with task 5):
   - Split `Models/Dto/BookRequests.cs` into `CreateBookRequestModel.cs` and `UpdateBookRequestModel.cs`.
   - Rename `Books` → `BookOutputModel`, `Authors` → `AuthorOutputModel`, `Review` → `ReviewOutputModel`, `BookSpec` → `BookSpecOutputModel`. JSON shape for the UI does not change (property names stay).
   - Add `CancellationToken cancellationToken` to all controller actions and repository methods; `string[]` query params in `SearchBooks` → `List<string>`.
7. UI side of phase 0 (UI repo): `ApiHelperService` base pieces + align API URL → see UI BACKLOG tasks 1-2.

### Phase 1 — Good catalog
8. Real search: `dbo.Books_Search` with text, author, category, price range, in-stock filter, sort and paging — all in the stored procedure. Response carries total count for paging.
9. Book details (specs, reviews, stock state) and author details (bio, books) served from the DB; "similar books" and "related" via stored procedures.
10. Audit the UI first: which pages/components (header, footer, home, search, details, similar) are real and which are placeholders → write the findings into UI BACKLOG.

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
25. Security + deployment pass: HTTPS, CORS for the real domain, secrets outside the repo, rate limiting on OTP/login, backups of the database.
26. Business items (not code, she owns them): return/refund policy, packaging standard for books, delivery-time promise, enamad/trust symbol, who handles customer support.

## SQL to run
<!-- scripts she still has to execute locally, in this order. Remove a line when she confirms. -->
- (none yet)

## For the UI repo
<!-- API contract changes the Angular app must follow. She copies these into the UI session. -->
- (after task 1) Every response is wrapped: `{ isSuccess, data, message, errors }`. Not-found is HTTP 200 with `isSuccess: false`. Validation errors = HTTP 400 with the same shape; server errors = 500 with the same shape.
- UI `public/env/env.js` points to `https://localhost:44388/api/`, but `Properties/launchSettings.json` uses `https://localhost:7106` / `http://localhost:5074` — align one of them.
- (planned, phases 2-4) New endpoint groups will appear: auth (OTP, email+password), profile/addresses, cart, orders, payment. Contracts are written here when each task is designed.

## Questions for her
- SQL Server instance: `localhost` or `localhost\SQLEXPRESS`?
- Prices as `DECIMAL(12,0)` numbers instead of strings (task 3)?
- Payment gateway choice and its production requirements (task 18).
- SMS provider for OTP (task 11).
