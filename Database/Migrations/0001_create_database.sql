-- 0001_create_database.sql
-- Creates the MorisakiBookshop database with a Persian, case-insensitive, accent-insensitive collation.
-- Safe to run more than once.
-- Run this one while connected to `master` (the database does not exist yet).
-- Every later script (0002 and up) is run against MorisakiBookshop.

IF DB_ID(N'MorisakiBookshop') IS NULL
BEGIN
    CREATE DATABASE MorisakiBookshop COLLATE Persian_100_CI_AI;
END
GO
