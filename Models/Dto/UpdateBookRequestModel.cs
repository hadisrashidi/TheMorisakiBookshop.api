using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class UpdateBookRequestModel
    {
        [Required, MinLength(1)]
        public string Title { get; set; } = "";

        [Required, MinLength(1)]
        public string Image { get; set; } = "";

        [Range(0, 1000000000000)]
        public decimal Price { get; set; }

        // null = no old price (book is not discounted)
        [Range(0, 1000000000000)]
        public decimal? OldPrice { get; set; }

        [Required]
        public int AuthorId { get; set; }

        public string Genre { get; set; } = "";

        public string Language { get; set; } = "";

        public string Description { get; set; } = "";

        [Range(0, int.MaxValue)]
        public int Stock { get; set; }

        public List<BookSpecRequestModel> Specs { get; set; } = new List<BookSpecRequestModel>();
    }
}
