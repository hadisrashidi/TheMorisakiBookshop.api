namespace TheMorisakiBookshop.Models
{
    public class AuthorOutputModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Image { get; set; } = "";
        public string Bio { get; set; } = "";
        public string Genre { get; set; } = "";
    }
}
