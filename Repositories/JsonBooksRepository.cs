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

        public async Task<List<Books>> GetRelatedAsync(int id, int count)
        {
            var books = await GetCacheAsync();
            var book = books.FirstOrDefault(b => b.Id == id);
            if (book == null)
            {
                return new List<Books>();
            }

            return books
                .Where(b => b.Id != id && b.Genre == book.Genre && !string.IsNullOrEmpty(book.Genre))
                .Take(count)
                .ToList();
        }

        public async Task<List<Books>> GetSimilarAsync(int id, int count)
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

            // Small catalogs won't always have more than one book per author —
            // fall back to genre so the section is never empty without reason.
            return books
                .Where(b => b.Id != id && b.Genre == book.Genre && !string.IsNullOrEmpty(book.Genre))
                .Take(count)
                .ToList();
        }

        public async Task<List<Books>> GetByAuthorAsync(int authorId)
        {
            var books = await GetCacheAsync();
            return books.Where(b => b.AuthorId == authorId).ToList();
        }

        public async Task<List<Books>> SearchAsync(string? query)
        {
            var books = await GetCacheAsync();
            if (string.IsNullOrWhiteSpace(query))
            {
                return books;
            }

            return books.Where(b =>
                b.Title.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                b.Genre.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                b.Specs.Any(s => s.Value.Contains(query, StringComparison.OrdinalIgnoreCase))
            ).ToList();
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
