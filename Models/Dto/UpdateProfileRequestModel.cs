using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class UpdateProfileRequestModel
    {
        [Required(ErrorMessage = "نام الزامی است.")]
        [MinLength(2, ErrorMessage = "نام باید حداقل ۲ نویسه باشد.")]
        [MaxLength(100, ErrorMessage = "نام باید حداکثر ۱۰۰ نویسه باشد.")]
        public string Name { get; set; } = "";

        // Jalali date like 1372/05/12, or empty.
        [RegularExpression(@"^(\d{4}/\d{2}/\d{2})?$", ErrorMessage = "تاریخ تولد را به شکل ۱۳۷۲/۰۵/۱۲ وارد کنید.")]
        public string Birthdate { get; set; } = "";
    }
}
