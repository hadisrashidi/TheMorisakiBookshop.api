# Backlog
<!-- open work only. Finished items go to archive/done.md with the date. Top = next. -->

## Open tasks
1. Introduce the response envelope (skill `dotnet-simple` → "Response envelope"): add `Models/CustomActionResult.cs` + `Models/CustomActionResultOfT.cs`, validation + exception handler in `Program.cs`, wrap every action in all 4 controllers in `Ok(new CustomActionResult...)` (replace `NotFound`, `NoContent`, `CreatedAtAction`). Contract change → see "For the UI repo".
2. Add NuGet packages `Dapper` and `Microsoft.Data.SqlClient` (ask her first, explain what each does); add `ConnectionStrings:Bookshop` to `appsettings.Development.json` (Windows auth).
3. Migration: create tables `Authors`, `Books`, `BookSpecs`, `Reviews` (re-runnable) + seed them from `Data/*.json`, keeping the same Ids (UI routes use them).
   - Decide with her: price columns as `DECIMAL(12,0)` instead of the current strings ("185000") — C# `Price`/`OldPrice` would become `decimal`, and the UI must be told.
4. Migration: stored procedures for every current repository method (Books: GetAll, GetById, GetNewest, GetFeatured, GetRelated, GetSimilar, GetByAuthor, Search, Insert, Update, Delete; Authors; Reviews: GetByBookId, GetByAuthorId).
5. Replace `Json*Repository` + `I*Repository` with Dapper repositories (`BooksRepository`, `AuthorsRepository`, `ReviewsRepository`); register them in `Program.cs`; delete `Data/*.json` and the `<None Include="Data\**\*.json" ...>` item in the csproj only after she confirms the DB works.
6. Bring existing code to skill `dotnet-simple` naming (best done together with task 5):
   - Split `Models/Dto/BookRequests.cs` into `CreateBookRequestModel.cs` and `UpdateBookRequestModel.cs`.
   - Rename `Books` → `BookOutputModel`, `Authors` → `AuthorOutputModel`, `Review` → `ReviewOutputModel`, `BookSpec` → `BookSpecOutputModel`. JSON shape for the UI does not change (property names stay).
   - Add `CancellationToken cancellationToken` to all controller actions and repository methods; `string[]` query params in `SearchBooks` → `List<string>`.
7. `BooksManagementController` has no auth — decide later with her (not urgent while local only).

## SQL to run
<!-- scripts she still has to execute locally, in this order. Remove a line when she confirms. -->
- (none yet)

## For the UI repo
<!-- API contract changes the Angular app must follow. She copies these into the UI session. -->
- (after task 1) Every response is wrapped: `{ isSuccess, data, message, errors }`. Not-found is HTTP 200 with `isSuccess: false`. Validation errors = HTTP 400 with the same shape; server errors = 500 with the same shape.
- UI `public/env/env.js` points to `https://localhost:44388/api/`, but `Properties/launchSettings.json` uses `https://localhost:7106` / `http://localhost:5074` — align one of them.

## Questions for her
- (none)
