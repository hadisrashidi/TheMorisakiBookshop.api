using System.Text.Json;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class JsonReviewsRepository : IReviewsRepository
    {
        private readonly string _path;
        private readonly SemaphoreSlim _lock = new(1, 1);
        private List<Review>? _cache;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public JsonReviewsRepository(IWebHostEnvironment env)
        {
            _path = Path.Combine(env.ContentRootPath, "Data", "Reviews.json");
        }

        private async Task<List<Review>> GetCacheAsync()
        {
            if (_cache != null)
            {
                return _cache;
            }

            await _lock.WaitAsync();
            try
            {
                if (_cache == null)
                {
                    if (File.Exists(_path))
                    {
                        var json = await File.ReadAllTextAsync(_path);
                        _cache = JsonSerializer.Deserialize<List<Review>>(json, JsonOptions) ?? new List<Review>();
                    }
                    else
                    {
                        _cache = new List<Review>();
                    }
                }
                return _cache;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<List<Review>> GetByBookIdAsync(int bookId)
        {
            var reviews = await GetCacheAsync();
            return reviews.Where(r => r.BookId == bookId).ToList();
        }

        public async Task<List<Review>> GetByBookIdsAsync(IEnumerable<int> bookIds)
        {
            var reviews = await GetCacheAsync();
            var ids = bookIds.ToHashSet();
            return reviews.Where(r => ids.Contains(r.BookId)).ToList();
        }
    }
}
