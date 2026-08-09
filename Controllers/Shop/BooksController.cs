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

        [HttpGet]
        public async Task<IActionResult> GetRelatedBooks(int id)
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Books.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json) ?? new List<Books>();

            var related = books.Where(b => b.Id != id).Take(3);

            return Ok(related);
        }

        [HttpGet]
        public async Task<IActionResult> GetSimilarBooks(int id)
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Books.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json) ?? new List<Books>();

            var similar = books.Where(b => b.Id != id).Reverse().Take(3);

            return Ok(similar);
        }

        [HttpGet]
        public async Task<IActionResult> SearchBooks(string? q)
        {

            var path = Path.Combine(Directory.GetCurrentDirectory(), "Data", "Books.json");
            var json = System.IO.File.ReadAllText(path);

            var books = JsonSerializer.Deserialize<List<Books>>(json) ?? new List<Books>();

            if (string.IsNullOrWhiteSpace(q))
            {
                return Ok(books);
            }

            var results = books.Where(b => b.Title.Contains(q, StringComparison.OrdinalIgnoreCase));

            return Ok(results);
        }
    }
}
