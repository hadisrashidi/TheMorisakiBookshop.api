namespace TheMorisakiBookshop.Models
{
    // Answer of dbo.Orders_CancelMine.
    public class OrderCancelResultModel
    {
        // Ok | NotFound | InvalidTransition
        public string Result { get; set; } = "";
        public string CurrentStatus { get; set; } = "";
    }
}
