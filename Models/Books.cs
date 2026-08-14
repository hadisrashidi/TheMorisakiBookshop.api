namespace TheMorisakiBookshop.Models
{
    public class Books
    {
        public int Id { get; set; } = 0;

        public string Price { get; set; } = "";
        public string OldPrice { get; set; } = "";

        public string Title { get; set; } = "";
        public string Image { get; set; } = "";

        // Structured fields used for search/filtering/relating books, kept in
        // addition to (not instead of) the matching display rows in Specs so
        // the existing book-detail spec table keeps working unchanged.
        public int AuthorId { get; set; }
        public string Genre { get; set; } = "";
        public DateTime AddedAt { get; set; }

        public List<BookSpec> Specs { get; set; } = new();
    }
}
