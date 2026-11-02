USE MorisakiBookshop;
GO

-- 0033_shop_settings.sql
-- The shop's own details (name, phone, address, social links, a note for the invoice) in ONE row of dbo.ShopSettings,
-- edited in the admin panel and used by the printed invoice (admin) and the footer (shop).
-- The seeded values are the SAMPLE data that was in the footer code: she replaces them in the admin panel.
-- Adding a new setting later = a new column here (a new script).
-- Safe to run more than once.

IF OBJECT_ID(N'dbo.ShopSettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ShopSettings
    (
        Id           INT            NOT NULL,
        ShopName     NVARCHAR(100)  NOT NULL,
        Phone        NVARCHAR(30)   NOT NULL,
        Email        NVARCHAR(100)  NOT NULL,
        Address      NVARCHAR(300)  NOT NULL,
        InstagramUrl NVARCHAR(200)  NOT NULL,
        TelegramUrl  NVARCHAR(200)  NOT NULL,
        WhatsappUrl  NVARCHAR(200)  NOT NULL,
        InvoiceNote  NVARCHAR(500)  NOT NULL,
        CONSTRAINT PK_ShopSettings PRIMARY KEY (Id),
        CONSTRAINT CK_ShopSettings_OneRow CHECK (Id = 1)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ShopSettings WHERE Id = 1)
BEGIN
    INSERT INTO dbo.ShopSettings (Id, ShopName, Phone, Email, Address, InstagramUrl, TelegramUrl, WhatsappUrl, InvoiceNote)
    VALUES (1, N'کتابفروشی موریساکی', N'09193757648', N'', N'تهران، شریعتی',
            N'https://instagram.com/morisaki.bookshop', N'https://t.me/morisaki_bookshop', N'https://wa.me/989193757648',
            N'از خرید شما سپاسگزاریم.');
END
GO

-- One row. Used by the shop footer (without the invoice note) and the admin panel.
CREATE OR ALTER PROCEDURE dbo.ShopSettings_Get
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ShopName, Phone, Email, Address, InstagramUrl, TelegramUrl, WhatsappUrl, InvoiceNote
    FROM dbo.ShopSettings
    WHERE Id = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.ShopSettings_Save
    @ShopName     NVARCHAR(100),
    @Phone        NVARCHAR(30),
    @Email        NVARCHAR(100),
    @Address      NVARCHAR(300),
    @InstagramUrl NVARCHAR(200),
    @TelegramUrl  NVARCHAR(200),
    @WhatsappUrl  NVARCHAR(200),
    @InvoiceNote  NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ShopSettings
    SET ShopName = @ShopName,
        Phone = @Phone,
        Email = @Email,
        Address = @Address,
        InstagramUrl = @InstagramUrl,
        TelegramUrl = @TelegramUrl,
        WhatsappUrl = @WhatsappUrl,
        InvoiceNote = @InvoiceNote
    WHERE Id = 1;
END
GO
