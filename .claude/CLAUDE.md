# TheMorisakiBookshop.api — instructions for Claude

Read this file fully at the start of every session. The memory files imported below are the
ground truth for state, decisions and open work. Read them before doing anything.

@memory/STATE.md
@memory/DECISIONS.md
@memory/BACKLOG.md
@memory/LEARNING.md

## Who you work with

- The owner is a **senior Angular developer who is learning .NET, C#, SQL Server and Dapper**
  through this project. She reads every line you write.
- Code must be easy on the eyes. Follow skill `dotnet-simple` for every C# line and skill
  `sql-server-dapper` for every SQL line / data access. These rules are not optional.
- Teach while you work: the first time a .NET / SQL concept shows up, explain it in chat in
  2-4 lines, with the Angular equivalent when one exists (e.g. `builder.Services.AddScoped` is
  like `providers: [...]`, `appsettings.json` is like `environment.ts`). Then add one line to
  `memory/LEARNING.md` so it is not explained twice.
- When there is a real choice to make (design, naming, a new package, a trade-off), ask her.
  Do not decide silently. Record the answer in `memory/DECISIONS.md`.

## First session after setup

If `memory/STATE.md` says `Onboarding: pending`: before any other work, walk her through
`.claude/ONBOARDING.md` (short, your own words, then ask if she has questions). Then set
`Onboarding: done (YYYY-MM-DD)` in STATE.md and commit it.

## Hard rules

- Data access = **Dapper + SQL Server stored procedures only**. No EF Core, no SQL text inside
  C#, no LINQ filtering/sorting in C# — filtering, sorting and joins live in the stored procedure.
- Database changes = a **new numbered, re-runnable `.sql` file in `Database/Migrations/`**
  (see skill `sql-server-dapper`). You never run SQL anywhere; she runs the scripts on her
  local database. After writing a script, add it to `BACKLOG.md` → "SQL to run".
- No new NuGet package without asking her first.
- Never commit secrets. The local Docker SQL Server login (`sa` + throwaway local password) may live in `appsettings.Development.json`; real/production credentials never go in the repo.
- Build must pass before you commit: `dotnet build`.

## Memory protocol — update DURING the session, not only at the end

Write to memory the moment something happens. Do not wait for the end of the prompt or the
end of the session.

| When this happens | Write it here |
|---|---|
| A decision is made (by her, or agreed with her) | `memory/DECISIONS.md` — newest on top, `YYYY-MM-DD: WHAT — WHY` |
| A decision replaces an older one | Replace the old line in DECISIONS.md; move the old one to `memory/archive/decisions.md` with `superseded YYYY-MM-DD by: ...` |
| A task is found, agreed, or postponed | `memory/BACKLOG.md` |
| A task is finished | Remove it from BACKLOG.md; add `YYYY-MM-DD: <task>` to top of `memory/archive/done.md` |
| A SQL script is written | `memory/BACKLOG.md` → "SQL to run" |
| She says she ran a script | Remove it from "SQL to run" |
| An API contract changes (route, request, response shape) | `memory/BACKLOG.md` → "For the UI repo" (the UI repo is separate; she carries these over) |
| What exists / what works changes | `memory/STATE.md` → Current state / Active work |
| A response changed anything | `memory/STATE.md` → Session log: one block per session, update it in place |
| A new concept is explained | `memory/LEARNING.md` |

Writing rules: terse bullets, exact file paths and names, dates as YYYY-MM-DD, WHAT + WHY,
no narration of the conversation, never secrets, never contradictions.

### Auto-archive (check at session start and every time you write memory)

- STATE.md Session log keeps the **5 newest** sessions. Move older ones to the top of
  `memory/archive/sessions.md`.
- Finished backlog items never stay in BACKLOG.md (see table above).
- Superseded decisions never stay in DECISIONS.md (see table above).
- Archive files are not imported; read them only when you need history.

### Committing

- Memory changes go in the **same commit** as the work they describe.
- Web sessions work on a branch. At the end of a session that changed files, remind her:
  "merge the PR before the next session, otherwise the next session will not see this memory".
- A Stop hook (`.claude/hooks/check-memory.sh`) blocks you from finishing when files changed but
  `.claude/memory/` did not. If it fires, update memory — do not work around it.
