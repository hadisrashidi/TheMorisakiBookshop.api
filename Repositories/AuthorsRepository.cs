using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Repositories
{
    public class AuthorsRepository
    {
        private readonly string _connectionString;

        public AuthorsRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<List<AuthorOutputModel>> GetAllAsync(CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                CommandDefinition command = new CommandDefinition(
                    "dbo.Authors_GetAll",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<AuthorOutputModel> authors = await connection.QueryAsync<AuthorOutputModel>(command);

                return authors.ToList();
            }
        }

        public async Task<AuthorOutputModel?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Authors_GetById",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                AuthorOutputModel? author = await connection.QueryFirstOrDefaultAsync<AuthorOutputModel>(command);

                return author;
            }
        }

        public async Task<List<AuthorOutputModel>> GetSimilarAsync(int id, int count, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Count", count);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Authors_GetSimilar",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<AuthorOutputModel> authors = await connection.QueryAsync<AuthorOutputModel>(command);

                return authors.ToList();
            }
        }
    }
}
