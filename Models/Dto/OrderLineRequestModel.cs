using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class OrderLineRequestModel
    {
        [Range(1, int.MaxValue, ErrorMessage = "شناسه کتاب درست نیست.")]
        public int BookId { get; set; }

        [Range(1, 20, ErrorMessage = "تعداد هر کتاب باید بین ۱ تا ۲۰ باشد.")]
        public int Quantity { get; set; }
    }
}
