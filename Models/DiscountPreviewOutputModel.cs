namespace TheMorisakiBookshop.Models
{
    // What the cart shows after a discount code is accepted.
    public class DiscountPreviewOutputModel
    {
        public string Code { get; set; } = "";
        public decimal DiscountAmount { get; set; }
    }
}
