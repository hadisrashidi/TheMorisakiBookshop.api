using Microsoft.AspNetCore.Mvc;
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
            var authors = await _authorsRepository.GetAllAsync();
            return Ok(authors);
        }

        [HttpGet]
        public async Task<IActionResult> GetAuthorById(int id)
        {
            var author = await _authorsRepository.GetByIdAsync(id);

            if (author == null)
            {
                return NotFound($"Author with id {id} not found.");
            }

            return Ok(author);
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarAuthors(int id)
        {
            var similar = await _authorsRepository.GetSimilarAsync(id, SimilarAuthorsCount);
            return Ok(similar);
        }
    }
}
