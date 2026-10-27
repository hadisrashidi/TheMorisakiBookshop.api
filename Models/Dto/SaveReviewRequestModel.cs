using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class SaveReviewRequestModel
    {
        [Range(1, int.MaxValue, ErrorMessage = "شناسه کتاب درست نیست.")]
        public int BookId { get; set; }

        [Range(1, 5, ErrorMessage = "امتیاز باید بین ۱ تا ۵ باشد.")]
        public int Rating { get; set; }

        [Required(ErrorMessage = "متن نظر الزامی است.")]
        [MinLength(3, ErrorMessage = "متن نظر خیلی کوتاه است.")]
        [MaxLength(2000, ErrorMessage = "متن نظر نباید بیشتر از ۲۰۰۰ نویسه باشد.")]
        public string Text { get; set; } = "";
    }
}
