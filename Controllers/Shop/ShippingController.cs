using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class ShippingController : BaseController
    {
        private readonly ShippingMethodsRepository _shippingMethodsRepository;

        public ShippingController(ShippingMethodsRepository shippingMethodsRepository)
        {
            _shippingMethodsRepository = shippingMethodsRepository;
        }

        // Public. subtotal = price of the books and city = city of the address make the checkout list (price for
        // this cart, Tehran-only methods hidden elsewhere); without both it is the information list.
        [HttpGet]
        public async Task<IActionResult> GetShippingMethods(decimal? subtotal, string? city, CancellationToken cancellationToken)
        {
            List<ShippingMethodOutputModel> methods = await _shippingMethodsRepository.GetActiveAsync(subtotal, city, cancellationToken);

            return Ok(new CustomActionResult<List<ShippingMethodOutputModel>>
            {
                IsSuccess = true,
                Data = methods
            });
        }
    }
}
