using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class CreateBookRequest
    {
        [Required, MinLength(1)]
        public string Title { get; set; } = "";

        [Required, MinLength(1)]
        public string Image { get; set; } = "";

        [Required, MinLength(1)]
        public string Price { get; set; } = "";

        public string OldPrice { get; set; } = "";

        [Required]
        public int AuthorId { get; set; }

        public string Genre { get; set; } = "";

        public List<BookSpec> Specs { get; set; } = new();
    }

    public class UpdateBookRequest
    {
        [Required, MinLength(1)]
        public string Title { get; set; } = "";

        [Required, MinLength(1)]
        public string Image { get; set; } = "";

        [Required, MinLength(1)]
        public string Price { get; set; } = "";

        public string OldPrice { get; set; } = "";

        [Required]
        public int AuthorId { get; set; }

        public string Genre { get; set; } = "";

        public List<BookSpec> Specs { get; set; } = new();
    }
}
