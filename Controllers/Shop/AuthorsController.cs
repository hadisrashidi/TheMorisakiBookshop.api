using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class AuthorsController : BaseController
    {
        private const int SimilarAuthorsCount = 6;

        private readonly AuthorsRepository _authorsRepository;

        public AuthorsController(AuthorsRepository authorsRepository)
        {
            _authorsRepository = authorsRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAuthors(CancellationToken cancellationToken)
        {
            List<AuthorOutputModel> authors = await _authorsRepository.GetAllAsync(cancellationToken);

            return Ok(new CustomActionResult<List<AuthorOutputModel>>
            {
                IsSuccess = true,
                Data = authors
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetAuthorById(int id, CancellationToken cancellationToken)
        {
            AuthorOutputModel? author = await _authorsRepository.GetByIdAsync(id, cancellationToken);

            if (author == null)
            {
                return Ok(new CustomActionResult<AuthorOutputModel>
                {
                    IsSuccess = false,
                    Message = $"Author with id {id} not found."
                });
            }

            return Ok(new CustomActionResult<AuthorOutputModel>
            {
                IsSuccess = true,
                Data = author
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarAuthors(int id, CancellationToken cancellationToken)
        {
            List<AuthorOutputModel> similar = await _authorsRepository.GetSimilarAsync(id, SimilarAuthorsCount, cancellationToken);

            return Ok(new CustomActionResult<List<AuthorOutputModel>>
            {
                IsSuccess = true,
                Data = similar
            });
        }
    }
}
