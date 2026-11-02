using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class SettingsController : BaseController
    {
        private readonly ShopSettingsRepository _shopSettingsRepository;

        public SettingsController(ShopSettingsRepository shopSettingsRepository)
        {
            _shopSettingsRepository = shopSettingsRepository;
        }

        // Public: name, phone, address and social links for the footer.
        [HttpGet]
        public async Task<IActionResult> GetShopInfo(CancellationToken cancellationToken)
        {
            ShopInfoOutputModel info = await _shopSettingsRepository.GetAsync(cancellationToken);

            return Ok(new CustomActionResult<ShopInfoOutputModel>
            {
                IsSuccess = true,
                Data = info
            });
        }
    }
}
