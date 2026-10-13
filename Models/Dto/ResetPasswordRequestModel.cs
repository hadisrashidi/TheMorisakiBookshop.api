using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class ResetPasswordRequestModel
    {
        [Required]
        [RegularExpression(@"^09\d{9}$", ErrorMessage = "Mobile must look like 09123456789.")]
        public string Mobile { get; set; } = "";

        [Required]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "The code has 6 digits.")]
        public string Code { get; set; } = "";

        [Required]
        [MinLength(8)]
        [MaxLength(100)]
        public string NewPassword { get; set; } = "";
    }
}
