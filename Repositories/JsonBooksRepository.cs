using System.Text.Json;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    // Reads/writes Data/Books.json. The catalog is small enough that keeping
    // it in memory (loaded once, mutated in place, rewritten to disk on
    // every change) is simpler and fast enough than round-tripping a real
    // database — a SemaphoreSlim keeps concurrent requests safe.
    public class JsonBooksRepository : IBooksRepository
    {
        private readonly string _path;
        private readonly SemaphoreSlim _lock = new(1, 1);
        private List<Books>? _cache;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public JsonBooksRepository(IWebHostEnvironment env)
        {
            _path = Path.Combine(env.ContentRootPath, "Data", "Books.json");
        }

        private async Task<List<Books>> LoadFromDiskAsync()
        {
            if (!File.Exists(_path))
            {
                return new List<Books>();
            }

            var json = await File.ReadAllTextAsync(_path);
            return JsonSerializer.Deserialize<List<Books>>(json, JsonOptions) ?? new List<Books>();
        }

        // For read-only access: locks only long enough to populate the cache
        // on first use, never while holding it during a mutation.
        private async Task<List<Books>> GetCacheAsync()
        {
            if (_cache != null)
            {
                return _cache;
            }

            await _lock.WaitAsync();
            try
            {
                _cache ??= await LoadFromDiskAsync();
                return _cache;
            }
            finally
            {
                _lock.Release();
            }
        }

        private async Task SaveAsync(List<Books> books)
        {
            var json = JsonSerializer.Serialize(books, new JsonSerializerOptions(JsonOptions) { WriteIndented = true });
            await File.WriteAllTextAsync(_path, json);
        }

        public async Task<List<Books>> GetAllAsync() => new(await GetCacheAsync());

        public async Task<Books?> GetByIdAsync(int id)
        {
            var books = await GetCacheAsync();
            return books.FirstOrDefault(b => b.Id == id);
        }

        public async Task<List<Books>> GetNewestAsync(int count)
        {
            var books = await GetCacheAsync();
            return books.OrderByDescending(b => b.AddedAt).Take(count).ToList();
        }

        // "محصولات مرتبط" (sidebar, book detail) — same author first; an
        // author with only one title falls back to other authors so the
        // section is never empty without reason.
        public async Task<List<Books>> GetRelatedAsync(int id, int count)
        {
            var books = await GetCacheAsync();
            var book = books.FirstOrDefault(b => b.Id == id);
            if (book == null)
            {
                return new List<Books>();
            }

            var byAuthor = books.Where(b => b.Id != id && b.AuthorId == book.AuthorId).Take(count).ToList();
            if (byAuthor.Count > 0)
            {
                return byAuthor;
            }

            return books
                .Where(b => b.Id != id && b.AuthorId != book.AuthorId)
                .Take(count)
                .ToList();
        }

        // "بر اساس سلیقه شما" (recommendations) — always other authors,
        // preferring a shared genre for relevance.
        public async Task<List<Books>> GetSimilarAsync(int id, int count)
        {
            var books = await GetCacheAsync();
            var book = books.FirstOrDefault(b => b.Id == id);
            if (book == null)
            {
                return new List<Books>();
            }

            var otherAuthors = books.Where(b => b.Id != id && b.AuthorId != book.AuthorId).ToList();

            var sameGenre = otherAuthors
                .Where(b => b.Genre == book.Genre && !string.IsNullOrEmpty(book.Genre))
                .Take(count)
                .ToList();

            if (sameGenre.Count >= count)
            {
                return sameGenre;
            }

            var remaining = count - sameGenre.Count;
            var alreadyPicked = sameGenre.Select(b => b.Id).ToHashSet();
            var fillers = otherAuthors.Where(b => !alreadyPicked.Contains(b.Id)).Take(remaining);

            return sameGenre.Concat(fillers).ToList();
        }

        public async Task<List<Books>> GetByAuthorAsync(int authorId)
        {
            var books = await GetCacheAsync();
            return books.Where(b => b.AuthorId == authorId).ToList();
        }

        public async Task<List<Books>> SearchAsync(string? query, string[]? genres = null, string[]? languages = null, string? sort = null)
        {
            var books = await GetCacheAsync();
            IEnumerable<Books> results = books;

            if (!string.IsNullOrWhiteSpace(query))
            {
                results = results.Where(b =>
                    b.Title.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                    b.Genre.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                    b.Specs.Any(s => s.Value.Contains(query, StringComparison.OrdinalIgnoreCase))
                );
            }

            if (genres is { Length: > 0 })
            {
                results = results.Where(b => genres.Contains(b.Genre));
            }

            if (languages is { Length: > 0 })
            {
                results = results.Where(b => languages.Contains(b.Language));
            }

            results = sort switch
            {
                "price_asc" => results.OrderBy(b => ParsePrice(b.Price)),
                "newest" => results.OrderByDescending(b => b.AddedAt),
                _ => results
            };

            return results.ToList();
        }

        // Prices are stored as pre-formatted strings (e.g. "185,000") for
        // display — strip separators to sort numerically.
        private static decimal ParsePrice(string price)
        {
            var digitsOnly = new string(price.Where(char.IsDigit).ToArray());
            return digitsOnly.Length == 0 ? 0 : decimal.Parse(digitsOnly);
        }

        public async Task<Books> CreateAsync(Books book)
        {
            await _lock.WaitAsync();
            try
            {
                _cache ??= await LoadFromDiskAsync();
                book.Id = _cache.Count == 0 ? 1 : _cache.Max(b => b.Id) + 1;
                book.AddedAt = DateTime.UtcNow;
                _cache.Add(book);
                await SaveAsync(_cache);
                return book;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<Books?> UpdateAsync(int id, Books book)
        {
            await _lock.WaitAsync();
            try
            {
                _cache ??= await LoadFromDiskAsync();
                var existing = _cache.FirstOrDefault(b => b.Id == id);
                if (existing == null)
                {
                    return null;
                }

                existing.Title = book.Title;
                existing.Image = book.Image;
                existing.Price = book.Price;
                existing.OldPrice = book.OldPrice;
                existing.AuthorId = book.AuthorId;
                existing.Genre = book.Genre;
                existing.Language = book.Language;
                existing.Specs = book.Specs;

                await SaveAsync(_cache);
                return existing;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            await _lock.WaitAsync();
            try
            {
                _cache ??= await LoadFromDiskAsync();
                var existing = _cache.FirstOrDefault(b => b.Id == id);
                if (existing == null)
                {
                    return false;
                }

                _cache.Remove(existing);
                await SaveAsync(_cache);
                return true;
            }
            finally
            {
                _lock.Release();
            }
        }
    }
}
