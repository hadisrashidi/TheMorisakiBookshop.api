# Database migrations

SQL scripts for the `MorisakiBookshop` SQL Server database.

- Run them yourself (SSMS / Azure Data Studio), against `MorisakiBookshop`, **in number order**.
- Every script is re-runnable: running one twice does no harm.
- Scripts are never edited after they are delivered; a change is always a new, higher number.
- Which scripts are still waiting to be run: `.claude/memory/BACKLOG.md` → "SQL to run".

`0001_create_database.sql` creates the database itself, so run it connected to `master`. Every script from `0008` on starts with `USE MorisakiBookshop;` so it cannot land in `master` by accident. Scripts `0002`-`0007` have no `USE`: select `MorisakiBookshop` in SSMS before running them.
