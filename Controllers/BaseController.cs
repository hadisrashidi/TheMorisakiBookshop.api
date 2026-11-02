using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace TheMorisakiBookshop.Controllers
{
    [Route("api/[controller]/[action]")]
 
    [ApiController]
    public class BaseController : ControllerBase
    {
        // The Persian sentence for the Reason answered by dbo.DiscountCodes_Check (used by the cart check and by placing an order).
        protected string GetDiscountMessage(string reason)
        {
            if (reason == "Inactive")
            {
                return "این کد تخفیف فعال نیست.";
            }

            if (reason == "NotStarted")
            {
                return "زمان استفاده از این کد هنوز شروع نشده است.";
            }

            if (reason == "Expired")
            {
                return "مهلت استفاده از این کد تمام شده است.";
            }

            if (reason == "MinSubtotal")
            {
                return "مبلغ کتاب‌های سبد برای استفاده از این کد کافی نیست.";
            }

            if (reason == "UsageLimit")
            {
                return "ظرفیت استفاده از این کد تمام شده است.";
            }

            if (reason == "UserLimit")
            {
                return "شما قبلاً از این کد استفاده کرده‌اید.";
            }

            return "کد تخفیف درست نیست.";
        }
    }
}
