namespace TheMorisakiBookshop.Models
{
    // Response envelope for endpoints that return no data (e.g. delete).
    public class CustomActionResult
    {
        public bool IsSuccess { get; set; }
        public string? Message { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
    }
}
