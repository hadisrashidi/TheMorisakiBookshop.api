namespace TheMorisakiBookshop.Models
{
    // The public details of the shop (footer, contact). The invoice note is for the admin only.
    public class ShopInfoOutputModel
    {
        public string ShopName { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Email { get; set; } = "";
        public string Address { get; set; } = "";
        public string InstagramUrl { get; set; } = "";
        public string TelegramUrl { get; set; } = "";
        public string WhatsappUrl { get; set; } = "";
    }
}
