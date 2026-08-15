using Microsoft.AspNetCore.Mvc;
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
            var reviews = await _reviewsRepository.GetByBookIdAsync(bookId);
            return Ok(reviews);
        }

        [HttpGet]
        public async Task<IActionResult> GetByAuthorId(int authorId)
        {
            var books = await _booksRepository.GetByAuthorAsync(authorId);
            var reviews = await _reviewsRepository.GetByBookIdsAsync(books.Select(b => b.Id));
            return Ok(reviews);
        }
    }
}
