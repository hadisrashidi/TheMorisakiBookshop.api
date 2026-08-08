using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Controllers.Shop
{

    public class AuthorsController : BaseController
    {

        [HttpGet]
        public async Task<IActionResult> GetAllAuthors()
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Authors.json");
            var json = System.IO.File.ReadAllText(path);

            var authors = JsonSerializer.Deserialize<List<Authors>>(json);

            return Ok(authors);
        }

    }
}
