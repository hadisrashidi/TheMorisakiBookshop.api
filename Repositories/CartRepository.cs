using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

namespace TheMorisakiBookshop.Repositories
{
    public class CartRepository
    {
        private readonly string _connectionString;

        public CartRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<List<CartItemOutputModel>> GetByUserIdAsync(int userId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.CartItems_GetByUserId",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<CartItemOutputModel> items = await connection.QueryAsync<CartItemOutputModel>(command);

                return items.ToList();
            }
        }

        // Returns false when the book does not exist or is hidden.
        public async Task<bool> SetQuantityAsync(int userId, SetCartQuantityRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@BookId", request.BookId);
                parameters.Add("@Quantity", request.Quantity);

                CommandDefinition command = new CommandDefinition(
                    "dbo.CartItems_SetQuantity",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        // The lines travel as JSON text, like the order lines.
        public async Task MergeAsync(int userId, MergeCartRequestModel request, CancellationToken cancellationToken)
        {
            string linesJson = JsonSerializer.Serialize(request.Lines);

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@Lines", linesJson);

                CommandDefinition command = new CommandDefinition(
                    "dbo.CartItems_Merge",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                await connection.ExecuteAsync(command);
            }
        }

        public async Task ClearAsync(int userId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.CartItems_Clear",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                await connection.ExecuteAsync(command);
            }
        }
    }
}
