using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Controllers.Shop
{

    public class BooksController : BaseController
    {

        [HttpGet]
        public async Task<IActionResult> GetAllBooks()
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Books.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json);

            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> GetNewBooks()
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "newBooks.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json);

            return Ok(books);
        }

        [HttpGet]
        public async Task<IActionResult> GetBookById(int id)
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Books.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json);

            var book = books?.FirstOrDefault(b => b.Id == id);

            if (book == null)
            {
                return NotFound($"Book with id {id} not found.");
            }

            return Ok(book);
        }
    }
}
