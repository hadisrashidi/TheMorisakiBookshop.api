using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class CreateBookRequestModel
    {
        [Required(ErrorMessage = "عنوان کتاب الزامی است.")]
        [MaxLength(200, ErrorMessage = "عنوان کتاب باید حداکثر ۲۰۰ نویسه باشد.")]
        public string Title { get; set; } = "";

        [Required(ErrorMessage = "تصویر کتاب الزامی است.")]
        [MaxLength(200, ErrorMessage = "آدرس تصویر باید حداکثر ۲۰۰ نویسه باشد.")]
        public string Image { get; set; } = "";

        [Range(0, 1000000000000, ErrorMessage = "قیمت باید عددی صفر یا بیشتر باشد.")]
        public decimal Price { get; set; }

        // null = no old price (book is not discounted)
        [Range(0, 1000000000000, ErrorMessage = "قیمت قبلی باید عددی صفر یا بیشتر باشد.")]
        public decimal? OldPrice { get; set; }

        [Required(ErrorMessage = "نویسنده الزامی است.")]
        public int AuthorId { get; set; }

        [MaxLength(50, ErrorMessage = "ژانر باید حداکثر ۵۰ نویسه باشد.")]
        public string Genre { get; set; } = "";

        [MaxLength(50, ErrorMessage = "زبان باید حداکثر ۵۰ نویسه باشد.")]
        public string Language { get; set; } = "";

        public string Description { get; set; } = "";

        [Range(0, int.MaxValue, ErrorMessage = "موجودی باید عددی صفر یا بیشتر باشد.")]
        public int Stock { get; set; }

        public List<BookSpecRequestModel> Specs { get; set; } = new List<BookSpecRequestModel>();
    }
}
