namespace TheMorisakiBookshop.Models
{
    public class AuthTokenOutputModel
    {
        public string Token { get; set; } = "";
        public DateTime ExpiresAt { get; set; }
        public UserOutputModel User { get; set; } = new UserOutputModel();
    }
}
