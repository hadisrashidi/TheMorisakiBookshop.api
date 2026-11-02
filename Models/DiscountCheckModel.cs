namespace TheMorisakiBookshop.Models
{
    // Answer of dbo.DiscountCodes_Check.
    public class DiscountCheckModel
    {
        public int CodeId { get; set; }

        // Ok | NotFound | Inactive | NotStarted | Expired | MinSubtotal | UsageLimit | UserLimit
        public string Reason { get; set; } = "";

        // Toman taken off the price of the books (0 when the code cannot be used).
        public decimal DiscountAmount { get; set; }
    }
}
