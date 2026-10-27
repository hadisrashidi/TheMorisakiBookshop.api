using System.Globalization;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class ReviewsController : BaseController
    {
        private readonly ReviewsRepository _reviewsRepository;

        public ReviewsController(ReviewsRepository reviewsRepository)
        {
            _reviewsRepository = reviewsRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetByBookId(int bookId, CancellationToken cancellationToken)
        {
            List<ReviewOutputModel> reviews = await _reviewsRepository.GetByBookIdAsync(bookId, cancellationToken);

            return Ok(new CustomActionResult<List<ReviewOutputModel>>
            {
                IsSuccess = true,
                Data = reviews
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetByAuthorId(int authorId, CancellationToken cancellationToken)
        {
            List<ReviewOutputModel> reviews = await _reviewsRepository.GetByAuthorIdAsync(authorId, cancellationToken);

            return Ok(new CustomActionResult<List<ReviewOutputModel>>
            {
                IsSuccess = true,
                Data = reviews
            });
        }

        // The review of the logged-in person for this book; Data is null when they have not written one.
        [Authorize]
        [HttpGet]
        public async Task<IActionResult> GetMyReview(int bookId, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            ReviewOutputModel? review = await _reviewsRepository.GetByUserAndBookAsync(userId, bookId, cancellationToken);

            return Ok(new CustomActionResult<ReviewOutputModel>
            {
                IsSuccess = true,
                Data = review
            });
        }

        // One review per person per book: saving again replaces the old review.
        [Authorize]
        [HttpPost]
        public async Task<IActionResult> SaveReview(SaveReviewRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();
            string date = GetJalaliToday();

            bool done = await _reviewsRepository.SaveAsync(userId, request, date, cancellationToken);

            CustomActionResult result = new CustomActionResult();
            result.IsSuccess = done;

            if (done == false)
            {
                result.Message = "این کتاب پیدا نشد.";
            }

            return Ok(result);
        }

        // Reviews keep their date as Jalali text (yyyy/MM/dd), like the older reviews.
        private string GetJalaliToday()
        {
            PersianCalendar calendar = new PersianCalendar();
            DateTime now = DateTime.UtcNow;

            int year = calendar.GetYear(now);
            int month = calendar.GetMonth(now);
            int day = calendar.GetDayOfMonth(now);

            return year.ToString("0000") + "/" + month.ToString("00") + "/" + day.ToString("00");
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }
    }
}
