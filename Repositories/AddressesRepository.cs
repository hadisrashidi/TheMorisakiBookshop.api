using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

namespace TheMorisakiBookshop.Repositories
{
    public class AddressesRepository
    {
        private readonly string _connectionString;

        public AddressesRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<List<AddressOutputModel>> GetByUserIdAsync(int userId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Addresses_GetByUserId",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<AddressOutputModel> addresses = await connection.QueryAsync<AddressOutputModel>(command);

                return addresses.ToList();
            }
        }

        public async Task<int> InsertAsync(int userId, SaveAddressRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                AddSaveParameters(parameters, request);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Addresses_Insert",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int newId = await connection.ExecuteScalarAsync<int>(command);

                return newId;
            }
        }

        // Returns false when the address does not exist or belongs to another user.
        public async Task<bool> UpdateAsync(int id, int userId, SaveAddressRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@UserId", userId);
                AddSaveParameters(parameters, request);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Addresses_Update",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        public async Task<bool> DeleteAsync(int id, int userId, CancellationToken cancellationToken)
        {
            return await RunByIdAsync("dbo.Addresses_Delete", id, userId, cancellationToken);
        }

        public async Task<bool> SetDefaultAsync(int id, int userId, CancellationToken cancellationToken)
        {
            return await RunByIdAsync("dbo.Addresses_SetDefault", id, userId, cancellationToken);
        }

        // Delete and SetDefault take the same two parameters and answer AffectedRows.
        private async Task<bool> RunByIdAsync(string procedureName, int id, int userId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@UserId", userId);

                CommandDefinition command = new CommandDefinition(
                    procedureName,
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        private void AddSaveParameters(DynamicParameters parameters, SaveAddressRequestModel request)
        {
            parameters.Add("@Title", request.Title.Trim());
            parameters.Add("@Recipient", request.Recipient.Trim());
            parameters.Add("@Phone", request.Phone);
            parameters.Add("@City", request.City.Trim());
            parameters.Add("@FullAddress", request.FullAddress.Trim());
            parameters.Add("@PostalCode", request.PostalCode);
            parameters.Add("@IsDefault", request.IsDefault);
        }
    }
}
