namespace TheMorisakiBookshop.Models
{
    // Internal: carries the password hash, so it is never sent to the UI (see UserOutputModel).
    public class UserModel
    {
        public int Id { get; set; }
        public string Mobile { get; set; } = "";
        public string? Email { get; set; }
        public string? PasswordHash { get; set; }
        public string? Name { get; set; }
        public string Role { get; set; } = "";
        public int FailedLoginCount { get; set; }
        public int LockedMinutesLeft { get; set; }
    }
}
