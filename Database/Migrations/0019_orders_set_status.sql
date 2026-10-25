USE MorisakiBookshop;
GO

-- 0019_orders_set_status.sql
-- dbo.Orders_SetStatus: the admin moves an order to its next status (and can set the tracking code).
-- Allowed moves (the ONLY place that decides this):
--   PendingPayment -> Paid | Cancelled        Paid    -> Packed | Cancelled
--   Packed         -> Shipped | Cancelled     Shipped -> Shipped (only to change the tracking code) | Delivered
--   Delivered and Cancelled are final.
-- Cancelling gives the stock of every line back to its book, in the same transaction.
-- Answers one row: Result = Ok | NotFound | InvalidTransition, CurrentStatus = the status now.
-- Safe to run more than once.

CREATE OR ALTER PROCEDURE dbo.Orders_SetStatus
    @Id           INT,
    @Status       NVARCHAR(30),
    @TrackingCode NVARCHAR(50) = NULL   -- NULL = leave the tracking code as it is
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Current NVARCHAR(30);

    BEGIN TRANSACTION;

    -- UPDLOCK: two admins clicking at the same time cannot both pass the check below.
    SELECT @Current = Status
    FROM dbo.Orders WITH (UPDLOCK, ROWLOCK)
    WHERE Id = @Id;

    IF @Current IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT N'NotFound' AS Result, N'' AS CurrentStatus;
        RETURN;
    END

    IF NOT (   (@Current = N'PendingPayment' AND @Status IN (N'Paid', N'Cancelled'))
            OR (@Current = N'Paid'           AND @Status IN (N'Packed', N'Cancelled'))
            OR (@Current = N'Packed'         AND @Status IN (N'Shipped', N'Cancelled'))
            OR (@Current = N'Shipped'        AND @Status IN (N'Shipped', N'Delivered')))
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT N'InvalidTransition' AS Result, @Current AS CurrentStatus;
        RETURN;
    END

    UPDATE dbo.Orders
    SET Status = @Status,
        TrackingCode = CASE WHEN @TrackingCode IS NULL THEN TrackingCode ELSE LTRIM(RTRIM(@TrackingCode)) END
    WHERE Id = @Id;

    IF @Status = N'Cancelled'
    BEGIN
        UPDATE b
        SET b.Stock = b.Stock + l.Quantity
        FROM dbo.Books AS b
        INNER JOIN dbo.OrderLines AS l ON l.BookId = b.Id
        WHERE l.OrderId = @Id;
    END

    COMMIT TRANSACTION;

    SELECT N'Ok' AS Result, @Status AS CurrentStatus;
END
GO
