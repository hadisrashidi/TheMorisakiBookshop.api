namespace TheMorisakiBookshop.Models
{
    // One row of dbo.BookSpecs_GetByBookIds. BookId tells us which book the spec belongs to;
    // it is not sent to the UI, so the UI keeps receiving { label, value } only.
    public class BookSpecRowModel
    {
        public int BookId { get; set; }
        public string Label { get; set; } = "";
        public string Value { get; set; } = "";
    }
}
