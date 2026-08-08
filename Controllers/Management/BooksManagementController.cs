using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace TheMorisakiBookshop.Controllers.Management
{
    public class BooksManagementController : BaseController
    {

        [HttpGet]
        public async Task<IActionResult> GetAllBooks()
        {
            return Ok();
        }
        [HttpGet]
        public async Task<IActionResult> GetAllNewBooks()
        {
            return Ok();
        }
        [HttpPost]
        public async Task<IActionResult> CreateBook()
        {
            return Ok();
        }
        [HttpPost]
        public async Task<IActionResult> UpdateBook()
        {
            return Ok();
        }
        [HttpPost]
        public async Task<IActionResult> DeleteBook()
        {
            return Ok();
        }
    }
}
