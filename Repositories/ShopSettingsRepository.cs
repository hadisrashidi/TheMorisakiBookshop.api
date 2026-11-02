using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class ShopSettingsRepository
    {
        private readonly string _connectionString;

        public ShopSettingsRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<ShopInfoOutputModel> GetAsync(CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                CommandDefinition command = new CommandDefinition(
                    "dbo.ShopSettings_Get",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                ShopInfoOutputModel? info = await connection.QueryFirstOrDefaultAsync<ShopInfoOutputModel>(command);

                return info ?? new ShopInfoOutputModel();
            }
        }
    }
}
