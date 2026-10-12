using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class ReviewsRepository
    {
        private readonly string _connectionString;

        public ReviewsRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<List<ReviewOutputModel>> GetByBookIdAsync(int bookId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@BookId", bookId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Reviews_GetByBookId",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<ReviewOutputModel> reviews = await connection.QueryAsync<ReviewOutputModel>(command);

                return reviews.ToList();
            }
        }

        public async Task<List<ReviewOutputModel>> GetByAuthorIdAsync(int authorId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@AuthorId", authorId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Reviews_GetByAuthorId",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<ReviewOutputModel> reviews = await connection.QueryAsync<ReviewOutputModel>(command);

                return reviews.ToList();
            }
        }
    }
}
