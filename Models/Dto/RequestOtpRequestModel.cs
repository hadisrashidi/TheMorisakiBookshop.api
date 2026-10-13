using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class RequestOtpRequestModel
    {
        [Required]
        [RegularExpression(@"^09\d{9}$", ErrorMessage = "Mobile must look like 09123456789.")]
        public string Mobile { get; set; } = "";
    }
}
