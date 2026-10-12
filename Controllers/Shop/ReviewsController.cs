using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
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
    }
}
