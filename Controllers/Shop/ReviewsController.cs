using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class ReviewsController : BaseController
    {
        private readonly IReviewsRepository _reviewsRepository;
        private readonly IBooksRepository _booksRepository;

        public ReviewsController(IReviewsRepository reviewsRepository, IBooksRepository booksRepository)
        {
            _reviewsRepository = reviewsRepository;
            _booksRepository = booksRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetByBookId(int bookId)
        {
            List<Review> reviews = await _reviewsRepository.GetByBookIdAsync(bookId);

            return Ok(new CustomActionResult<List<Review>>
            {
                IsSuccess = true,
                Data = reviews
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetByAuthorId(int authorId)
        {
            List<Books> books = await _booksRepository.GetByAuthorAsync(authorId);
            List<Review> reviews = await _reviewsRepository.GetByBookIdsAsync(books.Select(b => b.Id));

            return Ok(new CustomActionResult<List<Review>>
            {
                IsSuccess = true,
                Data = reviews
            });
        }
    }
}
