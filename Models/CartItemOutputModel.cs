namespace TheMorisakiBookshop.Models
{
    public class CartItemOutputModel
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Image { get; set; } = "";
        public decimal Price { get; set; }
        public decimal? OldPrice { get; set; }
        public int Stock { get; set; }
        public int Quantity { get; set; }
    }
}
