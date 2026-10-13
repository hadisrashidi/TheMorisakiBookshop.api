using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class VerifyOtpRequestModel
    {
        [Required(ErrorMessage = "شماره موبایل الزامی است.")]
        [RegularExpression(@"^09\d{9}$", ErrorMessage = "شماره موبایل را به شکل ۰۹۱۲۳۴۵۶۷۸۹ وارد کنید.")]
        public string Mobile { get; set; } = "";

        [Required(ErrorMessage = "کد تأیید الزامی است.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "کد تأیید ۶ رقم است.")]
        public string Code { get; set; } = "";

        // true = the token lasts Jwt:RememberMeDays instead of Jwt:ExpiresMinutes
        public bool RememberMe { get; set; }
    }
}
