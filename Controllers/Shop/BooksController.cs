using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class BooksController : BaseController
    {
        private const int NewBooksCount = 8;
        private const int FeaturedBooksCount = 4;
        private const int RelatedBooksCount = 3;
        private const int SimilarBooksCount = 4;

        private readonly IBooksRepository _booksRepository;

        public BooksController(IBooksRepository booksRepository)
        {
            _booksRepository = booksRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllBooks()
        {
            List<Books> books = await _booksRepository.GetAllAsync();

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetNewBooks()
        {
            List<Books> books = await _booksRepository.GetNewestAsync(NewBooksCount);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetFeaturedBooks()
        {
            List<Books> books = await _booksRepository.GetFeaturedAsync(FeaturedBooksCount);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetBookById(int id)
        {
            Books? book = await _booksRepository.GetByIdAsync(id);

            if (book == null)
            {
                return Ok(new CustomActionResult<Books>
                {
                    IsSuccess = false,
                    Message = $"Book with id {id} not found."
                });
            }

            return Ok(new CustomActionResult<Books>
            {
                IsSuccess = true,
                Data = book
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetRelatedBooks(int id)
        {
            List<Books> related = await _booksRepository.GetRelatedAsync(id, RelatedBooksCount);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = related
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarBooks(int id)
        {
            List<Books> similar = await _booksRepository.GetSimilarAsync(id, SimilarBooksCount);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = similar
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetBooksByAuthor(int authorId)
        {
            List<Books> books = await _booksRepository.GetByAuthorAsync(authorId);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> SearchBooks(string? q, [FromQuery] string[]? genres, [FromQuery] string[]? languages, string? sort, bool? inStockOnly)
        {
            List<Books> results = await _booksRepository.SearchAsync(q, genres, languages, sort, inStockOnly);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = results
            });
        }
    }
}
