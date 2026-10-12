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

        private readonly BooksRepository _booksRepository;

        public BooksController(BooksRepository booksRepository)
        {
            _booksRepository = booksRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllBooks(CancellationToken cancellationToken)
        {
            List<BookOutputModel> books = await _booksRepository.GetAllAsync(cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetNewBooks(CancellationToken cancellationToken)
        {
            List<BookOutputModel> books = await _booksRepository.GetNewestAsync(NewBooksCount, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetFeaturedBooks(CancellationToken cancellationToken)
        {
            List<BookOutputModel> books = await _booksRepository.GetFeaturedAsync(FeaturedBooksCount, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetBookById(int id, CancellationToken cancellationToken)
        {
            BookOutputModel? book = await _booksRepository.GetByIdAsync(id, cancellationToken);

            if (book == null)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = $"Book with id {id} not found."
                });
            }

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = book
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetRelatedBooks(int id, CancellationToken cancellationToken)
        {
            List<BookOutputModel> related = await _booksRepository.GetRelatedAsync(id, RelatedBooksCount, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = related
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarBooks(int id, CancellationToken cancellationToken)
        {
            List<BookOutputModel> similar = await _booksRepository.GetSimilarAsync(id, SimilarBooksCount, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = similar
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetBooksByAuthor(int authorId, CancellationToken cancellationToken)
        {
            List<BookOutputModel> books = await _booksRepository.GetByAuthorAsync(authorId, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpGet]
        public async Task<IActionResult> SearchBooks(string? q, [FromQuery] List<string> genres, [FromQuery] List<string> languages, int? authorId, decimal? minPrice, decimal? maxPrice, string? sort, bool inStockOnly, CancellationToken cancellationToken, int page = 1, int pageSize = 9)
        {
            BookSearchOutputModel results = await _booksRepository.SearchAsync(q, genres, languages, authorId, minPrice, maxPrice, inStockOnly, sort, page, pageSize, cancellationToken);

            return Ok(new CustomActionResult<BookSearchOutputModel>
            {
                IsSuccess = true,
                Data = results
            });
        }
    }
}
