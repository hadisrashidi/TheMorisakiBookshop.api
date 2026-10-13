namespace TheMorisakiBookshop.Models
{
    public class UserOutputModel
    {
        public int Id { get; set; }
        public string Mobile { get; set; } = "";
        public string? Email { get; set; }
        public bool HasPassword { get; set; }
        public string Role { get; set; } = "";
    }
}
