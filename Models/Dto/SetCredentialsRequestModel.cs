using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class SetCredentialsRequestModel
    {
        [Required]
        [EmailAddress]
        [MaxLength(256)]
        public string Email { get; set; } = "";

        [Required]
        [MinLength(8)]
        [MaxLength(100)]
        public string Password { get; set; } = "";
    }
}
