using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

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

        // The review this user wrote for this book, or null when there is none.
        public async Task<ReviewOutputModel?> GetByUserAndBookAsync(int userId, int bookId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@BookId", bookId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Reviews_GetByUserAndBook",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                ReviewOutputModel? review = await connection.QueryFirstOrDefaultAsync<ReviewOutputModel>(command);

                return review;
            }
        }

        // Creates or replaces the review. Returns false when the book does not exist or is hidden.
        public async Task<bool> SaveAsync(int userId, SaveReviewRequestModel request, string date, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@BookId", request.BookId);
                parameters.Add("@Rating", request.Rating);
                parameters.Add("@Text", request.Text.Trim());
                parameters.Add("@Date", date);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Reviews_Save",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }
    }
}
