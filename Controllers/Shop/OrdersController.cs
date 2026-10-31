using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    [Authorize]
    public class OrdersController : BaseController
    {
        private readonly OrdersRepository _ordersRepository;

        public OrdersController(OrdersRepository ordersRepository)
        {
            _ordersRepository = ordersRepository;
        }

        [HttpPost]
        public async Task<IActionResult> PlaceOrder(PlaceOrderRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            OrderPlacedModel placed = await _ordersRepository.PlaceAsync(userId, request, cancellationToken);

            if (placed.OrderId == 0)
            {
                return Ok(new CustomActionResult<int>
                {
                    IsSuccess = false,
                    Message = GetPlaceOrderFailureMessage(placed)
                });
            }

            return Ok(new CustomActionResult<int>
            {
                IsSuccess = true,
                Data = placed.OrderId,
                Message = "سفارش شما ثبت شد."
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetMyOrders(CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            List<OrderOutputModel> orders = await _ordersRepository.GetByUserIdAsync(userId, cancellationToken);

            return Ok(new CustomActionResult<List<OrderOutputModel>>
            {
                IsSuccess = true,
                Data = orders
            });
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }

        private string GetPlaceOrderFailureMessage(OrderPlacedModel placed)
        {
            if (placed.Problem == "NotEnoughStock")
            {
                return $"موجودی کتاب «{placed.ProblemTitle}» کافی نیست. تعداد را کم کنید یا آن را از سبد حذف کنید.";
            }

            if (placed.Problem == "BookNotFound")
            {
                return "یکی از کتاب‌های سبد دیگر موجود نیست. سبد را بررسی کنید.";
            }

            if (placed.Problem == "ShippingMethodInvalid")
            {
                return "روش ارسال انتخاب‌شده برای این شهر در دسترس نیست. روش دیگری انتخاب کنید.";
            }

            return "سبد خرید خالی است.";
        }
    }
}
