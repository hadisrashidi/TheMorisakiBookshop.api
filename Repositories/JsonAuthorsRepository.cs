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
    }
}
