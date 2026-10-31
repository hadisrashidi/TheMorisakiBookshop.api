namespace TheMorisakiBookshop.Models
{
    // Answer of dbo.Orders_Place. OrderId = 0 means nothing was saved; Problem says why.
    public class OrderPlacedModel
    {
        public int OrderId { get; set; }

        // "" | EmptyOrder | BookNotFound | NotEnoughStock | ShippingMethodInvalid
        public string Problem { get; set; } = "";
        public int ProblemBookId { get; set; }
        public string ProblemTitle { get; set; } = "";
    }
}
