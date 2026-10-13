using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class RegisterRequestModel
    {
        [Required(ErrorMessage = "شماره موبایل الزامی است.")]
        [RegularExpression(@"^09\d{9}$", ErrorMessage = "شماره موبایل را به شکل ۰۹۱۲۳۴۵۶۷۸۹ وارد کنید.")]
        public string Mobile { get; set; } = "";

        [Required(ErrorMessage = "کد تأیید الزامی است.")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "کد تأیید ۶ رقم است.")]
        public string Code { get; set; } = "";

        [Required(ErrorMessage = "ایمیل الزامی است.")]
        [EmailAddress(ErrorMessage = "ایمیل معتبر وارد کنید.")]
        [MaxLength(256, ErrorMessage = "ایمیل باید حداکثر ۲۵۶ نویسه باشد.")]
        public string Email { get; set; } = "";

        [Required(ErrorMessage = "رمز عبور الزامی است.")]
        [MinLength(8, ErrorMessage = "رمز عبور باید حداقل ۸ نویسه باشد.")]
        [MaxLength(100, ErrorMessage = "رمز عبور باید حداکثر ۱۰۰ نویسه باشد.")]
        public string Password { get; set; } = "";
    }
}
