using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class UsersRepository
    {
        private readonly string _connectionString;

        public UsersRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<UserModel> GetOrCreateByMobileAsync(string mobile, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Mobile", mobile);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_GetOrCreateByMobile",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                UserModel user = await connection.QueryFirstAsync<UserModel>(command);

                return user;
            }
        }

        public async Task<UserModel?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_GetById",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                UserModel? user = await connection.QueryFirstOrDefaultAsync<UserModel>(command);

                return user;
            }
        }

        public async Task<UserModel?> GetByEmailAsync(string email, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Email", email);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_GetByEmail",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                UserModel? user = await connection.QueryFirstOrDefaultAsync<UserModel>(command);

                return user;
            }
        }

        // Counts a wrong password; returns the minutes the account is locked now (0 = not locked).
        public async Task<int> RegisterFailedLoginAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_RegisterFailedLogin",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int lockedMinutesLeft = await connection.ExecuteScalarAsync<int>(command);

                return lockedMinutesLeft;
            }
        }

        public async Task ClearFailedLoginsAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_ClearFailedLogins",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                await connection.ExecuteAsync(command);
            }
        }

        // Returns 'Ok' | 'EmailTaken'
        public async Task<string> SetCredentialsAsync(int id, string email, string passwordHash, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Email", email);
                parameters.Add("@PasswordHash", passwordHash);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_SetCredentials",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                string status = await connection.ExecuteScalarAsync<string>(command) ?? "";

                return status;
            }
        }

        public async Task<bool> SetProfileAsync(int id, string name, string birthdate, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Name", name);
                parameters.Add("@Birthdate", birthdate);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_SetProfile",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        public async Task<bool> SetNameAsync(int id, string name, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Name", name);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_SetName",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        // Returns true when the account exists and already had a password
        public async Task<bool> ResetPasswordAsync(string mobile, string passwordHash, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Mobile", mobile);
                parameters.Add("@PasswordHash", passwordHash);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Users_ResetPassword",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }
    }
}
