using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public interface IBooksRepository
    {
        Task<List<Books>> GetAllAsync();
        Task<Books?> GetByIdAsync(int id);
        Task<List<Books>> GetNewestAsync(int count);
        Task<List<Books>> GetRelatedAsync(int id, int count);
        Task<List<Books>> GetSimilarAsync(int id, int count);
        Task<List<Books>> GetByAuthorAsync(int authorId);
        Task<List<Books>> SearchAsync(string? query, string[]? genres = null, string[]? languages = null, string? sort = null, bool? inStockOnly = null);
        Task<Books> CreateAsync(Books book);
        Task<Books?> UpdateAsync(int id, Books book);
        Task<bool> DeleteAsync(int id);
    }
}
