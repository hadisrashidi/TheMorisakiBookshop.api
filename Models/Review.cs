namespace TheMorisakiBookshop.Models
{
    public class Review
    {
        public int Id { get; set; }
        public int BookId { get; set; }
        public string ReviewerName { get; set; } = "";
        public int Rating { get; set; }
        public string Text { get; set; } = "";

        // Pre-formatted Jalali date string (e.g. "1403/04/12") — matches how
        // the rest of the app displays dates, without pulling in a Jalali
        // calendar library just to format seed content.
        public string Date { get; set; } = "";
    }
}
