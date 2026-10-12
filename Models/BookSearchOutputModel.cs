namespace TheMorisakiBookshop.Models
{
    public class BookSearchOutputModel
    {
        // The books of the requested page only.
        public List<BookOutputModel> Items { get; set; } = new List<BookOutputModel>();

        // All books matching the filters, over all pages (for the pager).
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }
}
