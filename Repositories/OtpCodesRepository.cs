using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace TheMorisakiBookshop.Repositories
{
    public class OtpCodesRepository
    {
        private readonly string _connectionString;

        public OtpCodesRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        // Returns 'Ok' | 'TooSoon' | 'TooMany'
        public async Task<string> CreateAsync(string mobile, string codeHash, int expiryMinutes, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Mobile", mobile);
                parameters.Add("@CodeHash", codeHash);
                parameters.Add("@ExpiryMinutes", expiryMinutes);

                CommandDefinition command = new CommandDefinition(
                    "dbo.OtpCodes_Create",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                string status = await connection.ExecuteScalarAsync<string>(command) ?? "";

                return status;
            }
        }

        // Returns 'Ok' | 'Invalid' | 'Expired' | 'Locked'
        public async Task<string> VerifyAsync(string mobile, string codeHash, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Mobile", mobile);
                parameters.Add("@CodeHash", codeHash);

                CommandDefinition command = new CommandDefinition(
                    "dbo.OtpCodes_Verify",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                string status = await connection.ExecuteScalarAsync<string>(command) ?? "";

                return status;
            }
        }
    }
}
