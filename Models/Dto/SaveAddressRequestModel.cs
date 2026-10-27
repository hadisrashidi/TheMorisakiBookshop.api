using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class SaveAddressRequestModel
    {
        [Required(ErrorMessage = "عنوان آدرس الزامی است.")]
        [MaxLength(50, ErrorMessage = "عنوان آدرس نباید بیشتر از ۵۰ نویسه باشد.")]
        public string Title { get; set; } = "";

        [Required(ErrorMessage = "نام گیرنده الزامی است.")]
        [MaxLength(100, ErrorMessage = "نام گیرنده نباید بیشتر از ۱۰۰ نویسه باشد.")]
        public string Recipient { get; set; } = "";

        [RegularExpression(@"^(09\d{9})?$", ErrorMessage = "شماره موبایل را به شکل ۰۹۱۲۳۴۵۶۷۸۹ وارد کنید.")]
        public string Phone { get; set; } = "";

        [Required(ErrorMessage = "شهر الزامی است.")]
        [MaxLength(50, ErrorMessage = "نام شهر نباید بیشتر از ۵۰ نویسه باشد.")]
        public string City { get; set; } = "";

        [Required(ErrorMessage = "نشانی الزامی است.")]
        [MaxLength(400, ErrorMessage = "نشانی نباید بیشتر از ۴۰۰ نویسه باشد.")]
        public string FullAddress { get; set; } = "";

        [RegularExpression(@"^(\d{10})?$", ErrorMessage = "کد پستی باید ۱۰ رقم باشد.")]
        public string PostalCode { get; set; } = "";

        public bool IsDefault { get; set; }
    }
}
