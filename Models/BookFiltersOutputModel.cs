namespace TheMorisakiBookshop.Models
{
    public class BookFiltersOutputModel
    {
        public decimal MinPrice { get; set; }
        public decimal MaxPrice { get; set; }
        public List<string> Genres { get; set; } = new List<string>();
        public List<string> Languages { get; set; } = new List<string>();
    }
}
