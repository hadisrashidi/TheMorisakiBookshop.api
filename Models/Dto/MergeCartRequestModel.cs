using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class MergeCartRequestModel
    {
        [Required(ErrorMessage = "سبد خرید خالی است.")]
        [MaxLength(50, ErrorMessage = "تعداد ردیف‌های سبد زیاد است.")]
        public List<SetCartQuantityRequestModel> Lines { get; set; } = new List<SetCartQuantityRequestModel>();
    }
}
