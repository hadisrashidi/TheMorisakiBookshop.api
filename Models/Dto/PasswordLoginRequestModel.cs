using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class PasswordLoginRequestModel
    {
        [Required(ErrorMessage = "ایمیل الزامی است.")]
        [EmailAddress(ErrorMessage = "ایمیل معتبر وارد کنید.")]
        public string Email { get; set; } = "";

        [Required(ErrorMessage = "رمز عبور الزامی است.")]
        public string Password { get; set; } = "";

        // true = the token lasts Jwt:RememberMeDays instead of Jwt:ExpiresMinutes
        public bool RememberMe { get; set; }
    }
}
