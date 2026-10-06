# Decisions
<!-- active decisions only, newest on top: YYYY-MM-DD: WHAT — WHY. Superseded ones go to archive/decisions.md -->

- 2026-10-04: Every endpoint returns the `CustomActionResult` / `CustomActionResult<T>` envelope `{ isSuccess, data, message, errors }`, always HTTP 200 for business outcomes (not found = `isSuccess: false`), 400/500 only from the framework with the same envelope — the Angular `ApiHelperService` / `ApiResponse<T>` (skill angular-stack in the UI repo) depends on this shape. No ActionExecuter; controllers build the envelope.
- 2026-10-04: Basic rules taken from the helper's own .NET skill (no layering/architecture from it): `RequestModel` / `OutputModel` / `Model` suffixes, `CancellationToken cancellationToken` on every async method (Dapper via `CommandDefinition`), `List<T>` in signatures (never `IEnumerable`/arrays), empty list instead of null, classes not records — proven conventions, kept consistent with the helper's other projects.
- 2026-10-04: Database name `MorisakiBookshop`, schema `dbo` — one small app, no need for more schemas.
- 2026-10-04: Table and column names in PascalCase and identical to the C# property names (`dbo.Books.Title` ↔ `Books.Title`) — Dapper then maps columns to properties with zero mapping code.
- 2026-10-04: Stored procedure names `dbo.<Table>_<Action>` (e.g. `dbo.Books_GetById`) — all procedures of one table sit together in SSMS.
- 2026-10-04: One migrations folder `Database/Migrations/`, numbered files `NNNN_short_description.sql`, every file re-runnable; a change is always a new file, never an edit of a delivered file — she just runs new files in number order.
- 2026-10-04: Request flow = Controller → Repository → stored procedure. No service layer unless real logic appears that does not belong in SQL — fewer layers to learn.
- 2026-10-04: Repositories are concrete classes, no interface while there is only one implementation — interfaces with one implementation are ceremony. (The `I*Repository` interfaces go away when the JSON repositories are replaced.)
- 2026-10-04: C# kept deliberately plain (skill `dotnet-simple`): one class per file, no expression-bodied members, no switch expressions / pattern tricks / LINQ magic / newest-syntax features — owner is learning .NET and must read every line easily.
- 2026-10-04: Data access only Dapper + stored procedures — owner's choice, to learn SQL Server properly.
