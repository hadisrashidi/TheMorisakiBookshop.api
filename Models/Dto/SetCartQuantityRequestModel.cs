using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class SetCartQuantityRequestModel
    {
        [Range(1, int.MaxValue, ErrorMessage = "شناسه کتاب درست نیست.")]
        public int BookId { get; set; }

        // 0 = remove the book from the cart.
        [Range(0, 20, ErrorMessage = "تعداد هر کتاب باید بین ۰ تا ۲۰ باشد.")]
        public int Quantity { get; set; }
    }
}
