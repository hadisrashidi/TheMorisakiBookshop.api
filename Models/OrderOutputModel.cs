namespace TheMorisakiBookshop.Models
{
    public class OrderOutputModel
    {
        public int Id { get; set; }

        // PendingPayment | Paid | Packed | Shipped | Delivered | Cancelled
        public string Status { get; set; } = "";
        public decimal Subtotal { get; set; }
        public decimal ShippingCost { get; set; }

        // Name of the shipping method at order time (empty for orders placed before shipping methods existed).
        public string ShippingMethodName { get; set; } = "";
        public decimal Total { get; set; }
        public string RecipientName { get; set; } = "";
        public string RecipientMobile { get; set; } = "";
        public string Address { get; set; } = "";
        public string PostalCode { get; set; } = "";
        public string TrackingCode { get; set; } = "";
        public DateTime CreatedAt { get; set; }
        public List<OrderLineOutputModel> Lines { get; set; } = new List<OrderLineOutputModel>();
    }
}
