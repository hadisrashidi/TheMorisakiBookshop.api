using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class UpdateProfileRequestModel
    {
        [Required(ErrorMessage = "نام الزامی است.")]
        [MinLength(2, ErrorMessage = "نام باید حداقل ۲ نویسه باشد.")]
        [MaxLength(100, ErrorMessage = "نام باید حداکثر ۱۰۰ نویسه باشد.")]
        public string Name { get; set; } = "";
    }
}
