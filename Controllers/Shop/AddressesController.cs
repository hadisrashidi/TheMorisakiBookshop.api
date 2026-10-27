using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    [Authorize]
    public class AddressesController : BaseController
    {
        private const string NotFoundMessage = "آدرس پیدا نشد.";

        private readonly AddressesRepository _addressesRepository;

        public AddressesController(AddressesRepository addressesRepository)
        {
            _addressesRepository = addressesRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyAddresses(CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            List<AddressOutputModel> addresses = await _addressesRepository.GetByUserIdAsync(userId, cancellationToken);

            return Ok(new CustomActionResult<List<AddressOutputModel>>
            {
                IsSuccess = true,
                Data = addresses
            });
        }

        [HttpPost]
        public async Task<IActionResult> AddAddress(SaveAddressRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            int newId = await _addressesRepository.InsertAsync(userId, request, cancellationToken);

            return Ok(new CustomActionResult<int>
            {
                IsSuccess = true,
                Data = newId
            });
        }

        [HttpPost]
        public async Task<IActionResult> UpdateAddress(int id, SaveAddressRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            bool found = await _addressesRepository.UpdateAsync(id, userId, request, cancellationToken);

            return Ok(BuildResult(found));
        }

        [HttpPost]
        public async Task<IActionResult> DeleteAddress(int id, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            bool found = await _addressesRepository.DeleteAsync(id, userId, cancellationToken);

            return Ok(BuildResult(found));
        }

        [HttpPost]
        public async Task<IActionResult> SetDefaultAddress(int id, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            bool found = await _addressesRepository.SetDefaultAsync(id, userId, cancellationToken);

            return Ok(BuildResult(found));
        }

        private CustomActionResult BuildResult(bool found)
        {
            CustomActionResult result = new CustomActionResult();
            result.IsSuccess = found;

            if (found == false)
            {
                result.Message = NotFoundMessage;
            }

            return result;
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }
    }
}
