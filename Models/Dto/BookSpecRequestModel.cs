using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class BookSpecRequestModel
    {
        [MaxLength(100, ErrorMessage = "عنوان مشخصات باید حداکثر ۱۰۰ نویسه باشد.")]
        public string Label { get; set; } = "";

        [MaxLength(200, ErrorMessage = "مقدار مشخصات باید حداکثر ۲۰۰ نویسه باشد.")]
        public string Value { get; set; } = "";
    }
}
