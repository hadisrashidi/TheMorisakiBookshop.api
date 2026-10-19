using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Management
{
    // Only logged-in admins (make one with dbo.Users_SetRole, see script 0011).
    // Books are never deleted: SetBookActive hides or shows them (old orders keep their book).
    [Authorize(Roles = "Admin")]
    public class BooksManagementController : BaseController
    {
        private readonly BooksRepository _booksRepository;
        private readonly AuthorsRepository _authorsRepository;

        public BooksManagementController(BooksRepository booksRepository, AuthorsRepository authorsRepository)
        {
            _booksRepository = booksRepository;
            _authorsRepository = authorsRepository;
        }

        // The admin list: like the shop search, but hidden books are included.
        [HttpGet]
        public async Task<IActionResult> SearchBooks(string? q, int? authorId, string? sort, CancellationToken cancellationToken, int page = 1, int pageSize = 20)
        {
            List<string> noGenres = new List<string>();
            List<string> noLanguages = new List<string>();

            BookSearchOutputModel results = await _booksRepository.SearchAsync(q, noGenres, noLanguages, authorId, null, null, false, sort, page, pageSize, true, cancellationToken);

            return Ok(new CustomActionResult<BookSearchOutputModel>
            {
                IsSuccess = true,
                Data = results
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetBookById(int id, CancellationToken cancellationToken)
        {
            BookOutputModel? book = await _booksRepository.GetByIdAsync(id, true, cancellationToken);

            if (book == null)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = $"کتابی با شناسه {id} پیدا نشد."
                });
            }

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = book
            });
        }

        [HttpPost]
        public async Task<IActionResult> CreateBook([FromBody] CreateBookRequestModel request, CancellationToken cancellationToken)
        {
            AuthorOutputModel? author = await _authorsRepository.GetByIdAsync(request.AuthorId, cancellationToken);

            if (author == null)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = "نویسنده‌ی انتخاب‌شده پیدا نشد."
                });
            }

            int newId = await _booksRepository.InsertAsync(request, cancellationToken);

            // Read the book back so the response has the computed fields (InStock, AddedAt, Specs).
            BookOutputModel? created = await _booksRepository.GetByIdAsync(newId, true, cancellationToken);

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = created
            });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateBook(int id, [FromBody] UpdateBookRequestModel request, CancellationToken cancellationToken)
        {
            AuthorOutputModel? author = await _authorsRepository.GetByIdAsync(request.AuthorId, cancellationToken);

            if (author == null)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = "نویسنده‌ی انتخاب‌شده پیدا نشد."
                });
            }

            bool found = await _booksRepository.UpdateAsync(id, request, cancellationToken);

            if (!found)
            {
                return Ok(new CustomActionResult<BookOutputModel>
                {
                    IsSuccess = false,
                    Message = $"کتابی با شناسه {id} پیدا نشد."
                });
            }

            BookOutputModel? updated = await _booksRepository.GetByIdAsync(id, true, cancellationToken);

            return Ok(new CustomActionResult<BookOutputModel>
            {
                IsSuccess = true,
                Data = updated
            });
        }

        // Quick stock change from the admin list.
        [HttpPost]
        public async Task<IActionResult> UpdateStock(int id, [FromBody] UpdateStockRequestModel request, CancellationToken cancellationToken)
        {
            bool found = await _booksRepository.SetStockAsync(id, request.Stock, cancellationToken);

            if (!found)
            {
                return Ok(new CustomActionResult
                {
                    IsSuccess = false,
                    Message = $"کتابی با شناسه {id} پیدا نشد."
                });
            }

            return Ok(new CustomActionResult
            {
                IsSuccess = true
            });
        }

        // Hides a book from the shop (isActive false) or shows it again (true).
        [HttpPost]
        public async Task<IActionResult> SetBookActive(int id, [FromBody] SetBookActiveRequestModel request, CancellationToken cancellationToken)
        {
            bool found = await _booksRepository.SetActiveAsync(id, request.IsActive, cancellationToken);

            if (!found)
            {
                return Ok(new CustomActionResult
                {
                    IsSuccess = false,
                    Message = $"کتابی با شناسه {id} پیدا نشد."
                });
            }

            return Ok(new CustomActionResult
            {
                IsSuccess = true
            });
        }
    }
}
