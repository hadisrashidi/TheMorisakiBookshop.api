using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    // Needs a login: some codes are limited per customer.
    [Authorize]
    public class DiscountsController : BaseController
    {
        private readonly DiscountCodesRepository _discountCodesRepository;

        public DiscountsController(DiscountCodesRepository discountCodesRepository)
        {
            _discountCodesRepository = discountCodesRepository;
        }

        // The cart asks: can I use this code, and how much does it take off? Placing the order checks it again.
        [HttpPost]
        public async Task<IActionResult> CheckCode(CheckDiscountRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            DiscountCheckModel check = await _discountCodesRepository.CheckAsync(request.Code, userId, request.Subtotal, cancellationToken);

            if (check.Reason != "Ok")
            {
                return Ok(new CustomActionResult<DiscountPreviewOutputModel>
                {
                    IsSuccess = false,
                    Message = GetDiscountMessage(check.Reason)
                });
            }

            DiscountPreviewOutputModel preview = new DiscountPreviewOutputModel();
            preview.Code = request.Code.Trim().ToUpperInvariant();
            preview.DiscountAmount = check.DiscountAmount;

            return Ok(new CustomActionResult<DiscountPreviewOutputModel>
            {
                IsSuccess = true,
                Data = preview
            });
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }
    }
}
