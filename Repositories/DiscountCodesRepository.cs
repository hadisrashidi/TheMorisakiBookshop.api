using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class DiscountCodesRepository
    {
        private readonly string _connectionString;

        public DiscountCodesRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        // Asks the database whether this person can use the code on books of this price (Reason = "Ok" when yes).
        public async Task<DiscountCheckModel> CheckAsync(string code, int userId, decimal subtotal, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Code", code);
                parameters.Add("@UserId", userId);
                parameters.Add("@Subtotal", subtotal);

                CommandDefinition command = new CommandDefinition(
                    "dbo.DiscountCodes_Check",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                DiscountCheckModel check = await connection.QuerySingleAsync<DiscountCheckModel>(command);

                return check;
            }
        }
    }
}
