using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Management
{
    // No authentication/authorization exists yet anywhere in this project —
    // these mutating endpoints are open to anyone who can reach the API.
    // Fine for local development; add an auth guard before this is exposed
    // publicly or an admin UI is built against it.
    public class BooksManagementController : BaseController
    {
        private const int NewBooksCount = 8;

        private readonly IBooksRepository _booksRepository;

        public BooksManagementController(IBooksRepository booksRepository)
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
        public async Task<IActionResult> GetAllNewBooks()
        {
            List<Books> books = await _booksRepository.GetNewestAsync(NewBooksCount);

            return Ok(new CustomActionResult<List<Books>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpPost]
        public async Task<IActionResult> CreateBook([FromBody] CreateBookRequest request)
        {
            Books book = new Books
            {
                Title = request.Title,
                Image = request.Image,
                Price = request.Price,
                OldPrice = request.OldPrice,
                AuthorId = request.AuthorId,
                Genre = request.Genre,
                Language = request.Language,
                Description = request.Description,
                InStock = request.InStock,
                Specs = request.Specs
            };

            Books created = await _booksRepository.CreateAsync(book);

            return Ok(new CustomActionResult<Books>
            {
                IsSuccess = true,
                Data = created
            });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateBook(int id, [FromBody] UpdateBookRequest request)
        {
            Books book = new Books
            {
                Title = request.Title,
                Image = request.Image,
                Price = request.Price,
                OldPrice = request.OldPrice,
                AuthorId = request.AuthorId,
                Genre = request.Genre,
                Language = request.Language,
                Description = request.Description,
                InStock = request.InStock,
                Specs = request.Specs
            };

            Books? updated = await _booksRepository.UpdateAsync(id, book);

            if (updated == null)
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
                Data = updated
            });
        }

        [HttpPost]
        public async Task<IActionResult> DeleteBook(int id)
        {
            bool deleted = await _booksRepository.DeleteAsync(id);

            if (!deleted)
            {
                return Ok(new CustomActionResult
                {
                    IsSuccess = false,
                    Message = $"Book with id {id} not found."
                });
            }

            return Ok(new CustomActionResult
            {
                IsSuccess = true
            });
        }
    }
}
