namespace TheMorisakiBookshop.Models
{
    public class ShippingMethodOutputModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";

        // Normal price (toman).
        public decimal Price { get; set; }

        // Free when the books cost at least this much; null = never free.
        public decimal? FreeAbove { get; set; }

        // What the customer pays for the books she asked about (0 when the method is free for that amount).
        public decimal Cost { get; set; }

        public string DeliveryText { get; set; } = "";
        public bool TehranOnly { get; set; }
    }
}
