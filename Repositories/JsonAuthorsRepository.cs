using System.Text.Json;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class JsonAuthorsRepository : IAuthorsRepository
    {
        private readonly string _path;
        private readonly SemaphoreSlim _lock = new(1, 1);
        private List<Authors>? _cache;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public JsonAuthorsRepository(IWebHostEnvironment env)
        {
            _path = Path.Combine(env.ContentRootPath, "Data", "Authors.json");
        }

        private async Task<List<Authors>> GetCacheAsync()
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
                        _cache = JsonSerializer.Deserialize<List<Authors>>(json, JsonOptions) ?? new List<Authors>();
                    }
                    else
                    {
                        _cache = new List<Authors>();
                    }
                }
                return _cache;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<List<Authors>> GetAllAsync() => new(await GetCacheAsync());

        public async Task<Authors?> GetByIdAsync(int id)
        {
            var authors = await GetCacheAsync();
            return authors.FirstOrDefault(a => a.Id == id);
        }

        public async Task<List<Authors>> GetSimilarAsync(int id, int count)
        {
            var authors = await GetCacheAsync();
            var author = authors.FirstOrDefault(a => a.Id == id);
            if (author == null)
            {
                return new List<Authors>();
            }

            var sameGenre = authors
                .Where(a => a.Id != id && a.Genre == author.Genre && !string.IsNullOrEmpty(author.Genre))
                .Take(count)
                .ToList();

            if (sameGenre.Count >= count)
            {
                return sameGenre;
            }

            // Small catalog — top up with other authors rather than showing
            // a half-empty "similar authors" row when few share a genre.
            var remaining = count - sameGenre.Count;
            var alreadyPicked = sameGenre.Select(a => a.Id).Append(id).ToHashSet();
            var fillers = authors
                .Where(a => !alreadyPicked.Contains(a.Id))
                .Take(remaining);

            return sameGenre.Concat(fillers).ToList();
        }
    }
}
