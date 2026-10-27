namespace TheMorisakiBookshop.Models
{
    public class AddressOutputModel
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Recipient { get; set; } = "";
        public string Phone { get; set; } = "";
        public string City { get; set; } = "";
        public string FullAddress { get; set; } = "";
        public string PostalCode { get; set; } = "";
        public bool IsDefault { get; set; }
    }
}
