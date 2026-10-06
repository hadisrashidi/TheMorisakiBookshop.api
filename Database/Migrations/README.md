# Database migrations

SQL scripts for the `MorisakiBookshop` SQL Server database.

- Run them yourself (SSMS / Azure Data Studio), against `MorisakiBookshop`, **in number order**.
- Every script is re-runnable: running one twice does no harm.
- Scripts are never edited after they are delivered; a change is always a new, higher number.
- Which scripts are still waiting to be run: `.claude/memory/BACKLOG.md` → "SQL to run".

First time only:
```sql
CREATE DATABASE MorisakiBookshop;
```
