namespace TheMorisakiBookshop.Models
{
    // Response envelope for endpoints that return data.
    public class CustomActionResult<T>
    {
        public bool IsSuccess { get; set; }
        public T? Data { get; set; }
        public string? Message { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
    }
}
