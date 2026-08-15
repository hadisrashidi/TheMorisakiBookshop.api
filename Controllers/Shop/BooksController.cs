using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class BooksController : BaseController
    {
        private const int NewBooksCount = 8;
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
            var books = await _booksRepository.GetAllAsync();
            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> GetNewBooks()
        {
            var books = await _booksRepository.GetNewestAsync(NewBooksCount);
            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> GetBookById(int id)
        {
            var book = await _booksRepository.GetByIdAsync(id);

            if (book == null)
            {
                return NotFound($"Book with id {id} not found.");
            }

            return Ok(book);
        }

        [HttpGet]
        public async Task<IActionResult> GetRelatedBooks(int id)
        {
            var related = await _booksRepository.GetRelatedAsync(id, RelatedBooksCount);
            return Ok(related);
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarBooks(int id)
        {
            var similar = await _booksRepository.GetSimilarAsync(id, SimilarBooksCount);
            return Ok(similar);
        }

        [HttpGet]
        public async Task<IActionResult> GetBooksByAuthor(int authorId)
        {
            var books = await _booksRepository.GetByAuthorAsync(authorId);
            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> SearchBooks(string? q, [FromQuery] string[]? genres, [FromQuery] string[]? languages, string? sort)
        {
            var results = await _booksRepository.SearchAsync(q, genres, languages, sort);
            return Ok(results);
        }
    }
}
