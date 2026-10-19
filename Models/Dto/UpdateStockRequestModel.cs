using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class UpdateStockRequestModel
    {
        [Range(0, int.MaxValue, ErrorMessage = "موجودی باید عددی صفر یا بیشتر باشد.")]
        public int Stock { get; set; }
    }
}
