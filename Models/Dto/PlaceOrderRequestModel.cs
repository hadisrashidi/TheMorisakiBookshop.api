using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class PlaceOrderRequestModel
    {
        [Required(ErrorMessage = "نام گیرنده الزامی است.")]
        [MaxLength(100, ErrorMessage = "نام گیرنده نباید بیشتر از ۱۰۰ نویسه باشد.")]
        public string RecipientName { get; set; } = "";

        [Required(ErrorMessage = "شماره موبایل گیرنده الزامی است.")]
        [RegularExpression(@"^09\d{9}$", ErrorMessage = "شماره موبایل را به شکل ۰۹۱۲۳۴۵۶۷۸۹ وارد کنید.")]
        public string RecipientMobile { get; set; } = "";

        [Required(ErrorMessage = "آدرس الزامی است.")]
        [MaxLength(500, ErrorMessage = "آدرس نباید بیشتر از ۵۰۰ نویسه باشد.")]
        public string Address { get; set; } = "";

        [RegularExpression(@"^(\d{10})?$", ErrorMessage = "کد پستی باید ۱۰ رقم باشد.")]
        public string PostalCode { get; set; } = "";

        [Required(ErrorMessage = "سبد خرید خالی است.")]
        [MinLength(1, ErrorMessage = "سبد خرید خالی است.")]
        [MaxLength(50, ErrorMessage = "تعداد ردیف‌های سفارش زیاد است.")]
        public List<OrderLineRequestModel> Lines { get; set; } = new List<OrderLineRequestModel>();
    }
}
