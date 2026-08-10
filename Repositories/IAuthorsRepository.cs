using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public interface IAuthorsRepository
    {
        Task<List<Authors>> GetAllAsync();
        Task<Authors?> GetByIdAsync(int id);
    }
}
