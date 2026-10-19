using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Storage;

namespace TheMorisakiBookshop.Controllers.Management
{
    [Authorize(Roles = "Admin")]
    public class ImagesManagementController : BaseController
    {
        private const long MaxImageBytes = 2 * 1024 * 1024;
        private const long MaxRequestBytes = 3 * 1024 * 1024;

        private readonly List<string> _allowedFolders = new List<string> { "covers", "authors" };
        private readonly List<string> _allowedExtensions = new List<string> { ".jpg", ".jpeg", ".png", ".webp" };

        private readonly ImageStorage _imageStorage;

        public ImagesManagementController(ImageStorage imageStorage)
        {
            _imageStorage = imageStorage;
        }

        // multipart/form-data with the field "file"; folder = "covers" (books) or "authors".
        // Answers the public path to store in Book.Image / Author.Image.
        [HttpPost]
        [RequestSizeLimit(MaxRequestBytes)]
        public async Task<IActionResult> UploadImage(IFormFile? file, string folder, CancellationToken cancellationToken)
        {
            if (file == null || file.Length == 0)
            {
                return Ok(new CustomActionResult<string>
                {
                    IsSuccess = false,
                    Message = "فایلی انتخاب نشده است."
                });
            }

            if (_allowedFolders.Contains(folder) == false)
            {
                return Ok(new CustomActionResult<string>
                {
                    IsSuccess = false,
                    Message = "پوشه‌ی مقصد معتبر نیست."
                });
            }

            string extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (_allowedExtensions.Contains(extension) == false)
            {
                return Ok(new CustomActionResult<string>
                {
                    IsSuccess = false,
                    Message = "فقط تصویر با فرمت jpg، png یا webp پذیرفته می‌شود."
                });
            }

            if (file.Length > MaxImageBytes)
            {
                return Ok(new CustomActionResult<string>
                {
                    IsSuccess = false,
                    Message = "حجم تصویر باید حداکثر ۲ مگابایت باشد."
                });
            }

            string path = await _imageStorage.SaveAsync(file, folder, cancellationToken);

            return Ok(new CustomActionResult<string>
            {
                IsSuccess = true,
                Data = path
            });
        }
    }
}
