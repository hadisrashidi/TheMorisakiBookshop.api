using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    [Authorize]
    public class CartController : BaseController
    {
        private readonly CartRepository _cartRepository;

        public CartController(CartRepository cartRepository)
        {
            _cartRepository = cartRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyCart(CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            List<CartItemOutputModel> items = await _cartRepository.GetByUserIdAsync(userId, cancellationToken);

            return Ok(new CustomActionResult<List<CartItemOutputModel>>
            {
                IsSuccess = true,
                Data = items
            });
        }

        [HttpPost]
        public async Task<IActionResult> SetQuantity(SetCartQuantityRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            bool done = await _cartRepository.SetQuantityAsync(userId, request, cancellationToken);

            CustomActionResult result = new CustomActionResult();
            result.IsSuccess = done;

            if (done == false)
            {
                result.Message = "این کتاب دیگر موجود نیست.";
            }

            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> MergeCart(MergeCartRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            await _cartRepository.MergeAsync(userId, request, cancellationToken);

            return Ok(new CustomActionResult { IsSuccess = true });
        }

        [HttpPost]
        public async Task<IActionResult> ClearCart(CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            await _cartRepository.ClearAsync(userId, cancellationToken);

            return Ok(new CustomActionResult { IsSuccess = true });
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }
    }
}
