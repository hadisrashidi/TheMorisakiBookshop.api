namespace TheMorisakiBookshop.Models
{
    public class OrderLineOutputModel
    {
        // Used to put the line on its order; the UI can ignore it.
        public int OrderId { get; set; }
        public int BookId { get; set; }
        public string Title { get; set; } = "";
        public string Image { get; set; } = "";

        // Price at purchase time, not the current book price.
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
    }
}
