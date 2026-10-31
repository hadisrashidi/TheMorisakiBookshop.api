using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class ShippingMethodsRepository
    {
        private readonly string _connectionString;

        public ShippingMethodsRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        // subtotal and city are optional: without them every active method is returned with its normal price.
        public async Task<List<ShippingMethodOutputModel>> GetActiveAsync(decimal? subtotal, string? city, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Subtotal", subtotal);
                parameters.Add("@City", city);

                CommandDefinition command = new CommandDefinition(
                    "dbo.ShippingMethods_GetActive",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<ShippingMethodOutputModel> methods = await connection.QueryAsync<ShippingMethodOutputModel>(command);

                return methods.ToList();
            }
        }
    }
}
