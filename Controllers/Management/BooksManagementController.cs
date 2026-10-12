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

        private readonly BooksRepository _booksRepository;

        public BooksManagementController(BooksRepository booksRepository)
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
        public async Task<IActionResult> GetAllNewBooks(CancellationToken cancellationToken)
        {
            List<BookOutputModel> books = await _booksRepository.GetNewestAsync(NewBooksCount, cancellationToken);

            return Ok(new CustomActionResult<List<BookOutputModel>>
            {
                IsSuccess = true,
                Data = books
            });
        }

        [HttpPost]
        public async Task<IActionResult> CreateBook([FromBody] CreateBookRequestModel request, CancellationToken cancellationToken)
        {
            int newId = await _booksRepository.InsertAsync(request, cancellationToken);

            // Read the book back so the response has the computed fields (InStock, AddedAt, Specs).
            BookOutputModel? created = await _booksRepository.GetByIdAsync(newId, cancellationToken);

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = created
            });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateBook(int id, [FromBody] UpdateBookRequestModel request, CancellationToken cancellationToken)
        {
            bool found = await _booksRepository.UpdateAsync(id, request, cancellationToken);

            if (!found)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = $"Book with id {id} not found."
                });
            }

            BookOutputModel? updated = await _booksRepository.GetByIdAsync(id, cancellationToken);

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = updated
            });
        }

        [HttpPost]
        public async Task<IActionResult> DeleteBook(int id, CancellationToken cancellationToken)
        {
            bool deleted = await _booksRepository.DeleteAsync(id, cancellationToken);

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
