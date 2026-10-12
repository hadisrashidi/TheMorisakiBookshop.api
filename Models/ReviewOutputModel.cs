namespace TheMorisakiBookshop.Models
{
    public class ReviewOutputModel
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public string ReviewerName { get; set; } = "";
        public int Rating { get; set; }
        public string Text { get; set; } = "";

        // Pre-formatted Jalali date text (e.g. "1403/04/12") — matches how the UI shows dates.
        public string Date { get; set; } = "";
    }
}
