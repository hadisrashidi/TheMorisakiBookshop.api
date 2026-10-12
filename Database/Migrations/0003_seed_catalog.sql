-- 0003_seed_catalog.sql
-- Copies the data of Data/*.json into dbo.Authors, dbo.Books, dbo.BookSpecs, dbo.Reviews, keeping the same Ids.
-- Only rows that are missing are inserted; existing rows are never changed.
-- Stock: books that were InStock = true get 10 (placeholder), the others 0 - set real numbers later.
-- Run after 0002_create_catalog_tables.sql. Safe to run more than once.

SET IDENTITY_INSERT dbo.Authors ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 1)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (1, N'Haruki Murakami', N'/authors/author-murakami.png', N'نویسنده ژاپنی، شناخته‌شده برای آثار رئالیسم جادویی و روایت‌های رویاگونه‌ای که فرهنگ پاپ و تنهایی مدرن را در هم می‌آمیزند.', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 2)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (2, N'Khaled Hosseini', N'/authors/author-hosseini.png', N'نویسنده افغان-آمریکایی، خالق رمان‌های پرفروشی که سرنوشت انسان‌ها را در دل تاریخ پرتلاطم افغانستان روایت می‌کنند.', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 3)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (3, N'Elif Shafak', N'/authors/author-shafak.png', N'نویسنده ترک-بریتانیایی، آثارش عرفان، عشق و هویت را در روایت‌هایی چندلایه و جهان‌شمول پیوند می‌زند.', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 4)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (4, N'صادق هدایت', N'/authors/author-hedayat.png', N'پیشگام داستان‌نویسی نوین فارسی؛ آثارش با فضایی تاریک و درون‌گرا، تأثیر عمیقی بر ادبیات معاصر ایران گذاشت.', N'ادبیات داستانی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 5)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (5, N'Fyodor Dostoevsky', N'/authors/author-dostoevsky.png', N'رمان‌نویس روس و از ستون‌های ادبیات کلاسیک جهان؛ آثارش به کاوش عمیق در روان و اخلاق انسانی شهرت دارند.', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 6)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (6, N'Kazuo Ishiguro', N'/authors/author-ishiguro.png', N'نویسنده بریتانیایی-ژاپنی و برنده جایزه نوبل ادبیات، شناخته‌شده برای نثر آرام و روایت‌های عمیقاً انسانی.', N'ادبیات داستانی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 7)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (7, N'Satoshi Yagisawa', N'/authors/author-yagisawa.png', N'نویسنده ژاپنی، خالق داستان‌هایی گرم و دلنشین درباره کتاب، خانواده و کتابفروشی‌های محله‌ای جیمبوچو.', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 8)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (8, N'فریبا وفی', N'/authors/author-vafi.png', N'نویسنده ایرانی، شناخته‌شده برای داستان‌های کوتاه و رمان‌هایی با نگاهی صمیمی به زندگی روزمره زنان.', N'داستان کوتاه');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 9)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (9, N'Agatha Christie', N'/authors/author-christie.png', N'ملقب به «ملکه جنایت»، یکی از پرفروش‌ترین نویسندگان تاریخ ادبیات و پیشگام رمان‌های معمایی کلاسیک.', N'جنایی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 10)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (10, N'Franz Kafka', N'/authors/author-kafka.png', N'نویسنده چک‌تبار آلمانی‌زبان، آثارش با فضایی اگزیستانسیال و پوچ، از ستون‌های ادبیات مدرن اروپا به شمار می‌روند.', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 11)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (11, N'Albert Camus', N'/authors/author-camus.png', N'نویسنده و فیلسوف فرانسوی-الجزایری، برنده جایزه نوبل و از چهره‌های اصلی فلسفه پوچی.', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Authors WHERE Id = 12)
BEGIN
    INSERT INTO dbo.Authors (Id, Name, Image, Bio, Genre)
    VALUES (12, N'Orhan Pamuk', N'/authors/author-pamuk.png', N'نویسنده ترک و برنده جایزه نوبل ادبیات، شناخته‌شده برای رمان‌هایی که تاریخ، هنر و هویت شرق و غرب را در هم می‌تنند.', N'رمان');
END

SET IDENTITY_INSERT dbo.Authors OFF;
GO

SET IDENTITY_INSERT dbo.Books ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 1)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (1, N'روزهایی در کتابفروشی موریساکی', 7, 185000, NULL, 10, N'/covers/book-morisaki.png', N'تاکاکو پس از یک جدایی تلخ، به کتابفروشی قدیمی عمویش در محله جیمبوچوی توکیو پناه می‌برد. در میان قفسه‌های کتاب‌های دست‌دوم و مشتری‌های عجیب‌وغریب مغازه، کم‌کم زندگی تازه‌ای برای خودش می‌سازد و با گذشته‌ای که از آن گریخته بود روبه‌رو می‌شود. روایتی آرام و دلگرم‌کننده درباره کتاب، خانواده و شروع دوباره.', N'رمان', N'فارسی', '2026-08-05 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 2)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (2, N'جنگل نروژی', 1, 195000, 220000, 10, N'/covers/book-norwegianwood.png', N'واتانابه با شنیدن یک آهنگ قدیمی به سال‌های دانشجویی‌اش در توکیوی دهه شصت بازمی‌گردد؛ به دوستی‌ها، عشق‌های ناتمام و از دست دادن‌هایی که او را ساختند. موراکامی در این رمان، تنهایی و بلوغ نسلی را با نثری آرام و اندوهگین روایت می‌کند.', N'رمان', N'فارسی', '2026-07-20 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 3)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (3, N'کافکا در کرانه', 1, 260000, NULL, 10, N'/covers/book-kafkashore.png', N'پسری پانزده‌ساله از خانه فرار می‌کند تا از پیشگویی تلخ پدرش بگریزد، و پیرمردی که با گربه‌ها حرف می‌زند در جست‌وجویی مرموز راهی سفر می‌شود. دو روایت موازی که در دنیایی میان واقعیت و رویا به هم می‌رسند؛ یکی از پیچیده‌ترین و ماندگارترین آثار موراکامی.', N'ادبیات داستانی', N'فارسی', '2026-06-15 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 4)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (4, N'بادبادک‌باز', 2, 175000, 210000, 10, N'/covers/book-kiterunner.png', N'امیر و حسن در کابل پیش از جنگ با هم بزرگ می‌شوند، اما یک خیانت کودکانه سایه‌اش را تا سال‌ها بعد و تا آن سوی دنیا می‌کشاند. روایتی تکان‌دهنده از دوستی، پشیمانی و تلاش برای جبران، در بستر تاریخ پرآشوب افغانستان.', N'رمان', N'فارسی', '2026-05-10 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 5)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (5, N'ملت عشق', 3, 165000, 195000, 10, N'/covers/book-fortyrules.png', N'الا، زن خانه‌دار آمریکایی، رمانی درباره شمس تبریزی و مولانا را برای بازخوانی می‌پذیرد و همین کتاب زندگی‌اش را زیرورو می‌کند. دو داستان موازی در دو قرن متفاوت، درباره عشق، عرفان و دگرگونی درونی.', N'رمان', N'فارسی', '2026-08-08 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 6)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (6, N'بوف کور', 4, 95000, NULL, 10, N'/covers/book-blindowl.png', N'راوی بی‌نام در انزوای اتاقش، کابوس‌ها و وسواس‌هایش را بر کاغذ می‌آورد؛ روایتی تب‌آلود که مرز میان واقعیت و توهم را محو می‌کند. مشهورترین اثر صادق هدایت و نقطه عطف داستان‌نویسی نوین فارسی.', N'ادبیات داستانی', N'فارسی', '2026-04-01 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 7)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (7, N'جنایت و مکافات', 5, 295000, 340000, 10, N'/covers/book-crimepunishment.png', N'راسکلنیکف، دانشجوی فقیر پترزبورگی، دست به قتلی می‌زند تا نظریه‌اش درباره انسان‌های برتر را بیازماید؛ اما وجدانش امانش نمی‌دهد. کاوشی عمیق در گناه، مجازات و امکان رستگاری، از شاهکارهای ادبیات جهان.', N'کلاسیک', N'فارسی', '2026-03-15 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 8)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (8, N'Klara and the Sun', 6, 310000, NULL, 10, N'/covers/book-klara.png', N'کلارا، یک دوست مصنوعی با قدرت مشاهده‌ای غیرعادی، از پشت ویترین مغازه دنیای آدم‌ها را تماشا می‌کند تا سرانجام به خانه‌ای راه پیدا کند. ایشی‌گورو از زاویه دید یک هوش مصنوعی، پرسش‌هایی درباره عشق، فداکاری و انسان بودن مطرح می‌کند.', N'ادبیات داستانی', N'انگلیسی', '2026-08-02 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 9)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (9, N'And Then There Were None', 9, 150000, 170000, 0, N'/covers/book-thennonewere.png', N'ده غریبه به جزیره‌ای دورافتاده دعوت می‌شوند و یکی‌یکی، مطابق یک ترانه قدیمی، کشته می‌شوند. هیچ‌کس نمی‌تواند جزیره را ترک کند و قاتل یکی از خودشان است. مشهورترین و پرفروش‌ترین معمای آگاتا کریستی.', N'جنایی', N'فارسی', '2026-02-20 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 10)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (10, N'مسخ', 10, 85000, NULL, 10, N'/covers/book-metamorphosis.png', N'گرگور زامزا صبح از خواب بیدار می‌شود و خود را تبدیل به حشره‌ای عظیم می‌یابد. کافکا با همین آغاز ساده، روایتی بی‌رحم از ازخودبیگانگی، طرد شدن و فروپاشی جایگاه انسان در خانواده و جامعه می‌سازد.', N'کلاسیک', N'فارسی', '2026-07-28 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 11)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (11, N'بیگانه', 11, 110000, 125000, 10, N'/covers/book-thestranger.png', N'مورسو در مراسم خاکسپاری مادرش اشک نمی‌ریزد و اندکی بعد، مردی را بی‌هیچ انگیزه روشنی می‌کشد. دادگاه بیش از جنایتش، بی‌تفاوتی‌اش را محاکمه می‌کند. رمانی بنیادین درباره پوچی و بیگانگی انسان مدرن.', N'کلاسیک', N'فارسی', '2026-01-10 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 12)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (12, N'پرنده من', 8, 120000, NULL, 10, N'/covers/book-mybird.png', N'زنی در آپارتمانی کوچک، میان روزمرگی خانه و رابطه‌ای که رو به سردی می‌رود، به گذشته و انتخاب‌هایش فکر می‌کند. فریبا وفی با نگاهی دقیق و صمیمی، زندگی درونی زنان را در جزئی‌ترین لحظه‌ها روایت می‌کند.', N'داستان کوتاه', N'فارسی', '2026-08-01 00:00:00');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE Id = 13)
BEGIN
    INSERT INTO dbo.Books (Id, Title, AuthorId, Price, OldPrice, Stock, Image, Description, Genre, Language, AddedAt)
    VALUES (13, N'نام من سرخ', 12, 205000, 230000, 0, N'/covers/book-myname.png', N'در استانبول قرن شانزدهم، یکی از نقاشان دربار عثمانی به قتل می‌رسد و رازی درباره سبک نقاشی فرنگی پشت آن پنهان است. پاموک با روایتی چندصدایی، معما، تاریخ هنر و کشمکش شرق و غرب را در هم می‌آمیزد.', N'رمان', N'فارسی', '2026-06-01 00:00:00');
END

SET IDENTITY_INSERT dbo.Books OFF;
GO

-- Specs: seeded once per book, only when the book has none yet.

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 1)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (1, 1, N'تعداد صفحات', N'212'),
        (1, 2, N'تعداد جلد', N'1'),
        (1, 3, N'زبان کتاب', N'فارسی'),
        (1, 4, N'زبان اصلی اثر', N'ژاپنی'),
        (1, 5, N'شابک / ISBN', N'9786222040113'),
        (1, 6, N'قطع', N'رقعی'),
        (1, 7, N'ناشر', N'نشر نو'),
        (1, 8, N'نوع جلد', N'شومیز'),
        (1, 9, N'نوع چاپ', N'سیاه و سفید'),
        (1, 10, N'نوع کاغذ', N'بالک'),
        (1, 11, N'نویسنده / نویسندگان', N'Satoshi Yagisawa'),
        (1, 12, N'ژانر', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 2)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (2, 1, N'تعداد صفحات', N'394'),
        (2, 2, N'تعداد جلد', N'1'),
        (2, 3, N'زبان کتاب', N'فارسی'),
        (2, 4, N'زبان اصلی اثر', N'ژاپنی'),
        (2, 5, N'شابک / ISBN', N'9789643624511'),
        (2, 6, N'قطع', N'رقعی'),
        (2, 7, N'ناشر', N'نشر نیکا'),
        (2, 8, N'نوع جلد', N'شومیز'),
        (2, 9, N'نوع چاپ', N'سیاه و سفید'),
        (2, 10, N'نوع کاغذ', N'بالک'),
        (2, 11, N'نویسنده / نویسندگان', N'Haruki Murakami'),
        (2, 12, N'ژانر', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 3)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (3, 1, N'تعداد صفحات', N'622'),
        (3, 2, N'تعداد جلد', N'1'),
        (3, 3, N'زبان کتاب', N'فارسی'),
        (3, 4, N'زبان اصلی اثر', N'ژاپنی'),
        (3, 5, N'شابک / ISBN', N'9786001760241'),
        (3, 6, N'قطع', N'رقعی'),
        (3, 7, N'ناشر', N'نشر نیکا'),
        (3, 8, N'نوع جلد', N'گالینگور'),
        (3, 9, N'نوع چاپ', N'سیاه و سفید'),
        (3, 10, N'نوع کاغذ', N'تحریر'),
        (3, 11, N'نویسنده / نویسندگان', N'Haruki Murakami'),
        (3, 12, N'ژانر', N'ادبیات داستانی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 4)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (4, 1, N'تعداد صفحات', N'372'),
        (4, 2, N'تعداد جلد', N'1'),
        (4, 3, N'زبان کتاب', N'فارسی'),
        (4, 4, N'زبان اصلی اثر', N'انگلیسی'),
        (4, 5, N'شابک / ISBN', N'9789643515254'),
        (4, 6, N'قطع', N'رقعی'),
        (4, 7, N'ناشر', N'نشر مروارید'),
        (4, 8, N'نوع جلد', N'شومیز'),
        (4, 9, N'نوع چاپ', N'سیاه و سفید'),
        (4, 10, N'نوع کاغذ', N'بالک'),
        (4, 11, N'نویسنده / نویسندگان', N'Khaled Hosseini'),
        (4, 12, N'ژانر', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 5)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (5, 1, N'تعداد صفحات', N'368'),
        (5, 2, N'تعداد جلد', N'1'),
        (5, 3, N'زبان کتاب', N'فارسی'),
        (5, 4, N'زبان اصلی اثر', N'انگلیسی'),
        (5, 5, N'شابک / ISBN', N'9786220102345'),
        (5, 6, N'قطع', N'رقعی'),
        (5, 7, N'ناشر', N'نشر ققنوس'),
        (5, 8, N'نوع جلد', N'شومیز'),
        (5, 9, N'نوع چاپ', N'سیاه و سفید'),
        (5, 10, N'نوع کاغذ', N'بالک'),
        (5, 11, N'نویسنده / نویسندگان', N'Elif Shafak'),
        (5, 12, N'ژانر', N'رمان');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 6)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (6, 1, N'تعداد صفحات', N'144'),
        (6, 2, N'تعداد جلد', N'1'),
        (6, 3, N'زبان کتاب', N'فارسی'),
        (6, 4, N'زبان اصلی اثر', N'فارسی'),
        (6, 5, N'شابک / ISBN', N'9789643514104'),
        (6, 6, N'قطع', N'پالتویی'),
        (6, 7, N'ناشر', N'انتشارات جاویدان'),
        (6, 8, N'نوع جلد', N'شومیز'),
        (6, 9, N'نوع چاپ', N'سیاه و سفید'),
        (6, 10, N'نوع کاغذ', N'بالک'),
        (6, 11, N'نویسنده / نویسندگان', N'صادق هدایت'),
        (6, 12, N'ژانر', N'ادبیات داستانی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 7)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (7, 1, N'تعداد صفحات', N'824'),
        (7, 2, N'تعداد جلد', N'1'),
        (7, 3, N'زبان کتاب', N'فارسی'),
        (7, 4, N'زبان اصلی اثر', N'روسی'),
        (7, 5, N'شابک / ISBN', N'9789643519925'),
        (7, 6, N'قطع', N'وزیری'),
        (7, 7, N'ناشر', N'انتشارات نیلوفر'),
        (7, 8, N'نوع جلد', N'گالینگور'),
        (7, 9, N'نوع چاپ', N'سیاه و سفید'),
        (7, 10, N'نوع کاغذ', N'تحریر'),
        (7, 11, N'نویسنده / نویسندگان', N'Fyodor Dostoevsky'),
        (7, 12, N'ژانر', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 8)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (8, 1, N'تعداد صفحات', N'303'),
        (8, 2, N'تعداد جلد', N'1'),
        (8, 3, N'زبان کتاب', N'انگلیسی'),
        (8, 4, N'زبان اصلی اثر', N'انگلیسی'),
        (8, 5, N'شابک / ISBN', N'9780571364886'),
        (8, 6, N'قطع', N'رقعی'),
        (8, 7, N'ناشر', N'Faber & Faber'),
        (8, 8, N'نوع جلد', N'شومیز'),
        (8, 9, N'نوع چاپ', N'سیاه و سفید'),
        (8, 10, N'نوع کاغذ', N'تحریر'),
        (8, 11, N'نویسنده / نویسندگان', N'Kazuo Ishiguro'),
        (8, 12, N'ژانر', N'ادبیات داستانی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 9)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (9, 1, N'تعداد صفحات', N'264'),
        (9, 2, N'تعداد جلد', N'1'),
        (9, 3, N'زبان کتاب', N'فارسی'),
        (9, 4, N'زبان اصلی اثر', N'انگلیسی'),
        (9, 5, N'شابک / ISBN', N'9789643697300'),
        (9, 6, N'قطع', N'رقعی'),
        (9, 7, N'ناشر', N'نشر هرمس'),
        (9, 8, N'نوع جلد', N'شومیز'),
        (9, 9, N'نوع چاپ', N'سیاه و سفید'),
        (9, 10, N'نوع کاغذ', N'بالک'),
        (9, 11, N'نویسنده / نویسندگان', N'Agatha Christie'),
        (9, 12, N'ژانر', N'جنایی');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 10)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (10, 1, N'تعداد صفحات', N'112'),
        (10, 2, N'تعداد جلد', N'1'),
        (10, 3, N'زبان کتاب', N'فارسی'),
        (10, 4, N'زبان اصلی اثر', N'آلمانی'),
        (10, 5, N'شابک / ISBN', N'9789643116308'),
        (10, 6, N'قطع', N'پالتویی'),
        (10, 7, N'ناشر', N'نشر ماهی'),
        (10, 8, N'نوع جلد', N'شومیز'),
        (10, 9, N'نوع چاپ', N'سیاه و سفید'),
        (10, 10, N'نوع کاغذ', N'بالک'),
        (10, 11, N'نویسنده / نویسندگان', N'Franz Kafka'),
        (10, 12, N'ژانر', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 11)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (11, 1, N'تعداد صفحات', N'154'),
        (11, 2, N'تعداد جلد', N'1'),
        (11, 3, N'زبان کتاب', N'فارسی'),
        (11, 4, N'زبان اصلی اثر', N'فرانسه'),
        (11, 5, N'شابک / ISBN', N'9789643514128'),
        (11, 6, N'قطع', N'پالتویی'),
        (11, 7, N'ناشر', N'انتشارات نیلوفر'),
        (11, 8, N'نوع جلد', N'شومیز'),
        (11, 9, N'نوع چاپ', N'سیاه و سفید'),
        (11, 10, N'نوع کاغذ', N'بالک'),
        (11, 11, N'نویسنده / نویسندگان', N'Albert Camus'),
        (11, 12, N'ژانر', N'کلاسیک');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 12)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (12, 1, N'تعداد صفحات', N'160'),
        (12, 2, N'تعداد جلد', N'1'),
        (12, 3, N'زبان کتاب', N'فارسی'),
        (12, 4, N'زبان اصلی اثر', N'فارسی'),
        (12, 5, N'شابک / ISBN', N'9789643118500'),
        (12, 6, N'قطع', N'رقعی'),
        (12, 7, N'ناشر', N'نشر مرکز'),
        (12, 8, N'نوع جلد', N'شومیز'),
        (12, 9, N'نوع چاپ', N'سیاه و سفید'),
        (12, 10, N'نوع کاغذ', N'بالک'),
        (12, 11, N'نویسنده / نویسندگان', N'فریبا وفی'),
        (12, 12, N'ژانر', N'داستان کوتاه');
END

IF NOT EXISTS (SELECT 1 FROM dbo.BookSpecs WHERE BookId = 13)
BEGIN
    INSERT INTO dbo.BookSpecs (BookId, SortOrder, Label, Value)
    VALUES
        (13, 1, N'تعداد صفحات', N'572'),
        (13, 2, N'تعداد جلد', N'1'),
        (13, 3, N'زبان کتاب', N'فارسی'),
        (13, 4, N'زبان اصلی اثر', N'ترکی'),
        (13, 5, N'شابک / ISBN', N'9789643692800'),
        (13, 6, N'قطع', N'رقعی'),
        (13, 7, N'ناشر', N'نشر چشمه'),
        (13, 8, N'نوع جلد', N'شومیز'),
        (13, 9, N'نوع چاپ', N'سیاه و سفید'),
        (13, 10, N'نوع کاغذ', N'بالک'),
        (13, 11, N'نویسنده / نویسندگان', N'Orhan Pamuk'),
        (13, 12, N'ژانر', N'رمان');
END

GO

SET IDENTITY_INSERT dbo.Reviews ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 1)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (1, 1, N'سارا احمدی', 5, N'فضای گرم کتابفروشی موریساکی آدم رو واقعاً با خودش می‌بره، از اون کتاب‌هاییه که دلت می‌خواد آروم‌آروم تمومش کنی.', N'1403/09/14');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 2)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (2, 1, N'امیر رضایی', 4, N'داستان ساده و صمیمی‌ای داره، بیشتر برای وقت‌هایی که دنبال یه روایت آرام و دلنشین هستید مناسبه.', N'1403/11/02');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 3)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (3, 2, N'نگار حسینی', 5, N'موراکامی توی این کتاب نوستالژی و تنهایی نسل جوان ژاپن رو فوق‌العاده روایت کرده.', N'1403/08/21');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 4)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (4, 2, N'علی کریمی', 4, N'ترجمه روان بود و فضاسازی کتاب بی‌نظیره، هرچند ریتم داستان برای بعضی‌ها ممکنه کند باشه.', N'1404/01/07');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 5)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (5, 3, N'مریم صادقی', 5, N'یکی از پیچیده‌ترین و در عین حال زیباترین رمان‌های موراکامیه؛ لایه‌های نمادین زیادی داره.', N'1403/10/03');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 6)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (6, 3, N'حسین مرادی', 4, N'خط روایی موازی کمی گیج‌کننده بود ولی در نهایت همه‌چیز سر جای خودش قرار می‌گیره.', N'1403/12/19');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 7)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (7, 4, N'زهرا نوری', 5, N'از اون کتاب‌هاییه که تا مدت‌ها بعد از تمام شدن ذهنت رو درگیر خودش نگه می‌داره.', N'1403/07/11');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 8)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (8, 4, N'محمد اکبری', 5, N'روایت دوستی و پشیمانی خالد حسینی رو با چنان صداقتی نوشته که آدم اشک می‌ریزه.', N'1403/09/30');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 9)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (9, 5, N'فاطمه رستمی', 4, N'دو خط داستانی موازی به‌خوبی به هم گره خورده‌اند، هرچند بخش‌های عرفانی برای همه جذاب نیست.', N'1403/06/18');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 10)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (10, 5, N'رضا قاسمی', 5, N'کتابی درباره عشق و تحول درونی که با زبانی ساده و تأثیرگذار نوشته شده.', N'1404/02/04');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 11)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (11, 6, N'سپیده جعفری', 5, N'بوف کور رو باید آروم و چند بار خوند؛ فضای تاریک و شاعرانه‌اش بی‌نظیره.', N'1403/05/09');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 12)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (12, 6, N'کاوه شریفی', 4, N'زبان هدایت سنگین و نمادینه، برای اولین تجربه با ادبیات کلاسیک فارسی شاید چالش‌برانگیز باشه.', N'1403/11/25');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 13)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (13, 7, N'لیلا محمدی', 5, N'شاهکار داستایفسکی در کاوش روان یک قاتل؛ تعلیق روانی کتاب فوق‌العاده‌ست.', N'1403/04/12');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 14)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (14, 7, N'بابک تقوی', 5, N'با اینکه حجم زیادی داره ولی هر صفحه‌اش ارزش خوندن داره، از کتاب‌های ماندگار ادبیات جهانه.', N'1403/10/28');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 15)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (15, 8, N'آیدا کاظمی', 4, N'ایشی‌گورو از زاویه دید یک هوش مصنوعی داستانی لطیف و غم‌انگیز درباره عشق و انسانیت نوشته.', N'1403/08/02');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 16)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (16, 8, N'پویا اسدی', 5, N'روایت آرام و دقیقش دقیقاً همون چیزیه که از ایشی‌گورو انتظار داری؛ تأثیرگذار و ماندگار.', N'1404/01/16');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 17)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (17, 9, N'نیلوفر یزدانی', 5, N'بهترین رمان معمایی آگاتا کریستی که تا آخرین صفحه غافلگیرت می‌کنه.', N'1403/09/06');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 18)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (18, 9, N'فرهاد ابراهیمی', 4, N'پیچش داستانی عالیه، فقط شخصیت‌های زیاد اولش کمی گیج‌کننده‌ست.', N'1403/12/01');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 19)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (19, 10, N'شیوا رحیمی', 5, N'مسخ کافکا هنوز هم یکی از عجیب‌ترین و در عین حال واقعی‌ترین روایت‌های ازخودبیگانگیه.', N'1403/06/29');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 20)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (20, 10, N'آرش نجفی', 4, N'کوتاه ولی سنگینه؛ بعد از خوندنش باید یه مدت بهش فکر کنی تا کامل جا بیفته.', N'1404/02/20');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 21)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (21, 11, N'مینا فرهادی', 5, N'بیگانه کامو دقیقاً همون چیزیه که اسمش رو داره؛ سرد، صادق و فراموش‌نشدنی.', N'1403/07/23');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 22)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (22, 11, N'سامان ولی‌زاده', 5, N'فلسفه پوچی رو کامو با داستانی کوتاه و در عین حال عمیق روایت کرده.', N'1403/11/14');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 23)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (23, 12, N'طاهره کریمی', 4, N'فریبا وفی با نثری ساده و صمیمی زندگی روزمره رو با ظرافت خاصی روایت می‌کنه.', N'1403/05/17');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 24)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (24, 12, N'امید صالحی', 4, N'داستانی کوتاه ولی پر از جزئیات ظریف از دل زندگی عادی یک زن.', N'1403/10/09');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 25)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (25, 13, N'دنیا عزیزی', 5, N'پاموک تاریخ، هنر و عشق رو در بستر استانبول قرن شانزدهم فوق‌العاده به تصویر کشیده.', N'1403/08/15');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Reviews WHERE Id = 26)
BEGIN
    INSERT INTO dbo.Reviews (Id, BookId, ReviewerName, Rating, Text, Date)
    VALUES (26, 13, N'یوسف رستگار', 5, N'روایت چندصدایی کتاب خیلی هوشمندانه‌ست و تا آخر تعلیق داستان رو حفظ می‌کنه.', N'1404/01/28');
END

SET IDENTITY_INSERT dbo.Reviews OFF;
GO
