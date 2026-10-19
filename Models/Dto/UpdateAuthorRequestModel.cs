using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class UpdateAuthorRequestModel
    {
        [Required(ErrorMessage = "نام نویسنده الزامی است.")]
        [MaxLength(100, ErrorMessage = "نام نویسنده باید حداکثر ۱۰۰ نویسه باشد.")]
        public string Name { get; set; } = "";

        [MaxLength(200, ErrorMessage = "آدرس تصویر باید حداکثر ۲۰۰ نویسه باشد.")]
        public string Image { get; set; } = "";

        public string Bio { get; set; } = "";

        [MaxLength(50, ErrorMessage = "ژانر باید حداکثر ۵۰ نویسه باشد.")]
        public string Genre { get; set; } = "";
    }
}
