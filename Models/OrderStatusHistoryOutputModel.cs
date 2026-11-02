namespace TheMorisakiBookshop.Models
{
    // One step in the life of an order: it got this status at this time (UTC).
    public class OrderStatusHistoryOutputModel
    {
        public int OrderId { get; set; }
        public string Status { get; set; } = "";
        public DateTime ChangedAt { get; set; }
    }
}
