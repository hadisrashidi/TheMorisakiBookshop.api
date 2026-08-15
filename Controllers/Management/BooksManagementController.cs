using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Controllers.Shop;
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
            var books = await _booksRepository.GetAllAsync();
            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> GetAllNewBooks()
        {
            var books = await _booksRepository.GetNewestAsync(NewBooksCount);
            return Ok(books);
        }

        [HttpPost]
        public async Task<IActionResult> CreateBook([FromBody] CreateBookRequest request)
        {
            var book = new Books
            {
                Title = request.Title,
                Image = request.Image,
                Price = request.Price,
                OldPrice = request.OldPrice,
                AuthorId = request.AuthorId,
                Genre = request.Genre,
                Language = request.Language,
                Specs = request.Specs
            };

            var created = await _booksRepository.CreateAsync(book);
            return CreatedAtAction(
                actionName: nameof(BooksController.GetBookById),
                controllerName: "Books",
                routeValues: new { id = created.Id },
                value: created);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateBook(int id, [FromBody] UpdateBookRequest request)
        {
            var book = new Books
            {
                Title = request.Title,
                Image = request.Image,
                Price = request.Price,
                OldPrice = request.OldPrice,
                AuthorId = request.AuthorId,
                Genre = request.Genre,
                Language = request.Language,
                Specs = request.Specs
            };

            var updated = await _booksRepository.UpdateAsync(id, book);

            if (updated == null)
            {
                return NotFound($"Book with id {id} not found.");
            }

            return Ok(updated);
        }

        [HttpPost]
        public async Task<IActionResult> DeleteBook(int id)
        {
            var deleted = await _booksRepository.DeleteAsync(id);

            if (!deleted)
            {
                return NotFound($"Book with id {id} not found.");
            }

            return NoContent();
        }
    }
}
