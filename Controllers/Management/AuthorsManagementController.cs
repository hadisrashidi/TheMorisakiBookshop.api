using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Management
{
    // Only logged-in admins. The list and the single author come from the public AuthorsController.
    [Authorize(Roles = "Admin")]
    public class AuthorsManagementController : BaseController
    {
        private readonly AuthorsRepository _authorsRepository;

        public AuthorsManagementController(AuthorsRepository authorsRepository)
        {
            _authorsRepository = authorsRepository;
        }

        [HttpPost]
        public async Task<IActionResult> CreateAuthor([FromBody] CreateAuthorRequestModel request, CancellationToken cancellationToken)
        {
            int newId = await _authorsRepository.InsertAsync(request, cancellationToken);

            AuthorOutputModel? created = await _authorsRepository.GetByIdAsync(newId, cancellationToken);

            return Ok(new CustomActionResult<AuthorOutputModel>
            {
                IsSuccess = true,
                Data = created
            });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateAuthor(int id, [FromBody] UpdateAuthorRequestModel request, CancellationToken cancellationToken)
        {
            bool found = await _authorsRepository.UpdateAsync(id, request, cancellationToken);

            if (!found)
            {
                return Ok(new CustomActionResult<AuthorOutputModel>
                {
                    IsSuccess = false,
                    Message = $"نویسنده‌ای با شناسه {id} پیدا نشد."
                });
            }

            AuthorOutputModel? updated = await _authorsRepository.GetByIdAsync(id, cancellationToken);

            return Ok(new CustomActionResult<AuthorOutputModel>
            {
                IsSuccess = true,
                Data = updated
            });
        }
    }
}
