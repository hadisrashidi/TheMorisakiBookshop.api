using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class AuthorsController : BaseController
    {
        private const int SimilarAuthorsCount = 6;

        private readonly IAuthorsRepository _authorsRepository;

        public AuthorsController(IAuthorsRepository authorsRepository)
        {
            _authorsRepository = authorsRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAuthors()
        {
            List<Authors> authors = await _authorsRepository.GetAllAsync();

            return Ok(new CustomActionResult<List<Authors>>
            {
                IsSuccess = true,
                Data = authors
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetAuthorById(int id)
        {
            Authors? author = await _authorsRepository.GetByIdAsync(id);

            if (author == null)
            {
                return Ok(new CustomActionResult<Authors>
                {
                    IsSuccess = false,
                    Message = $"Author with id {id} not found."
                });
            }

            return Ok(new CustomActionResult<Authors>
            {
                IsSuccess = true,
                Data = author
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarAuthors(int id)
        {
            List<Authors> similar = await _authorsRepository.GetSimilarAsync(id, SimilarAuthorsCount);

            return Ok(new CustomActionResult<List<Authors>>
            {
                IsSuccess = true,
                Data = similar
            });
        }
    }
}
