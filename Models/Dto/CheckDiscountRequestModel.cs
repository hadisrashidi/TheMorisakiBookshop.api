using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class CheckDiscountRequestModel
    {
        [Required(ErrorMessage = "کد تخفیف را وارد کنید.")]
        [MaxLength(50, ErrorMessage = "کد تخفیف خیلی طولانی است.")]
        public string Code { get; set; } = "";

        // The price of the books in the cart. Only for the preview: the order is always priced again from the database.
        [Range(0, 1000000000000, ErrorMessage = "مبلغ سبد درست نیست.")]
        public decimal Subtotal { get; set; }
    }
}
