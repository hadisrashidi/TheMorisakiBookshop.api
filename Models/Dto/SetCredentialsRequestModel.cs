using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class SetCredentialsRequestModel
    {
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
