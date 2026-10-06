# Onboarding — how working with Claude on this repo goes

Claude: explain this to her in the first session after setup, short and in your own words.

## 1. What Claude reads every session
- `.claude/CLAUDE.md` loads automatically. It pulls in the memory files, so every new session
  starts knowing the state, the decisions, the backlog and what she has already learned.
- Skills in `.claude/skills/` load when the task needs them:
  - `dotnet-simple` — how C# is written here (plain, one class per file, no tricks).
  - `sql-server-dapper` — tables, stored procedures, migration scripts, Dapper calls.

## 2. The memory files (`.claude/memory/`) — plain markdown, she can edit them too
- `STATE.md` — what exists now, what is in progress, last 5 sessions.
- `DECISIONS.md` — every decision with its reason, so nothing is argued twice.
- `BACKLOG.md` — open tasks, "SQL to run", changes the UI must follow, questions for her.
- `LEARNING.md` — her cheat sheet: every .NET/SQL concept explained so far, with the Angular equivalent.
- `archive/` — old sessions, finished tasks, replaced decisions. Kept, not loaded.
- Claude updates these the moment something is decided or done, not only at the end.
  A Stop hook refuses to let Claude finish if code changed and memory did not.

## 3. One rule for her: merge before the next session
Claude on the web works on a new branch each session and opens a PR. Memory lives in the repo,
so **if the PR is not merged, the next session will not see what happened.** Merge (or at least
keep working on the same branch) before starting the next session.

## 4. Database workflow
1. Claude writes a numbered script in `Database/Migrations/` (e.g. `0001_create_books_table.sql`)
   and lists it under "SQL to run" in BACKLOG.md.
2. She opens it in SSMS (or Azure Data Studio) against her local `MorisakiBookshop` database and runs it.
3. She tells Claude "ran 0001" and Claude removes it from the list.
- Every script is **re-runnable**: running it twice does no harm (it checks "does it already exist?").
- A change is always a **new** file, never an edit of an old one. Run new files in number order.
- Claude never connects to any database. She is the only one who runs SQL.

## 5. How a request flows (with the Angular picture)
```
Angular HttpClient ──HTTP──> Controller ──> Repository ──Dapper──> Stored procedure ──> Table
```
- Controller ≈ the API "endpoint" her Angular services call. Thin: call repository, wrap the result in
  `CustomActionResult<T>` `{ isSuccess, data, message, errors }` — exactly the `ApiResponse<T>` the Angular `ApiHelperService` expects.
- Repository ≈ an Angular data service, but it talks to SQL Server instead of HTTP.
- Dapper = tiny library that runs a stored procedure and fills C# objects from the rows
  (columns are named exactly like the C# properties, so no mapping code).
- Stored procedure = the real query logic (filter, sort, join) lives in SQL, not in C#.
- `Program.cs` registrations ≈ Angular `providers`; constructor injection works the same way.

## 6. Code style she can expect
- One class per file, one controller per file, full names, explicit types, `if`/`foreach` with braces.
- No expression-bodied members, no switch expressions, no clever LINQ, no newest-C# shortcuts.
- She can say "explain this" on any line, anytime.

## 7. Where we start
The first backlog items move the data from the JSON files in `Data/` into SQL Server
(packages → tables + seed → stored procedures → Dapper repositories). See `memory/BACKLOG.md`.

## 8. What she needs locally
- .NET 8 SDK, SQL Server (Developer or Express edition), SSMS.
- An empty database: `CREATE DATABASE MorisakiBookshop;`
- Connection string uses `Server=localhost`; with SQL Server Express it is `Server=localhost\SQLEXPRESS` — tell Claude which one she has.
- Run the API: `dotnet run` (Swagger opens in Development).
