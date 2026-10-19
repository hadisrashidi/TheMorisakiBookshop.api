namespace TheMorisakiBookshop.Models
{
    public class BookOutputModel
    {
        public int Id { get; set; }

        public decimal Price { get; set; }
        public decimal? OldPrice { get; set; }

        public string Title { get; set; } = "";
        public string Image { get; set; } = "";
        public string Description { get; set; } = "";

        // Stock is the stored truth; InStock is computed by the stored procedure as Stock > 0.
        public int Stock { get; set; }
        public bool InStock { get; set; }

        // false = hidden from the shop (only the admin panel sees hidden books).
        public bool IsActive { get; set; }

        // Structured fields used for search/filtering/relating books, kept in
        // addition to (not instead of) the matching display rows in Specs.
        public int AuthorId { get; set; }
        public string Genre { get; set; } = "";
        public string Language { get; set; } = "";
        public DateTime AddedAt { get; set; }

        public List<BookSpecOutputModel> Specs { get; set; } = new List<BookSpecOutputModel>();
    }
}
