using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public interface IReviewsRepository
    {
        Task<List<Review>> GetByBookIdAsync(int bookId);
        Task<List<Review>> GetByBookIdsAsync(IEnumerable<int> bookIds);
    }
}
