using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

namespace TheMorisakiBookshop.Repositories
{
    public class BooksRepository
    {
        private readonly string _connectionString;

        public BooksRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        public async Task<List<BookOutputModel>> GetAllAsync(CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetAll",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        public async Task<BookOutputModel?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetById",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                BookOutputModel? book = await connection.QueryFirstOrDefaultAsync<BookOutputModel>(command);

                if (book == null)
                {
                    return null;
                }

                List<BookOutputModel> books = new List<BookOutputModel>();
                books.Add(book);
                await AddSpecsAsync(books, cancellationToken);

                return book;
            }
        }

        public async Task<List<BookOutputModel>> GetNewestAsync(int count, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Count", count);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetNewest",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        public async Task<List<BookOutputModel>> GetFeaturedAsync(int count, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Count", count);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetFeatured",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        public async Task<List<BookOutputModel>> GetRelatedAsync(int id, int count, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Count", count);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetRelated",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        public async Task<List<BookOutputModel>> GetSimilarAsync(int id, int count, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Count", count);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetSimilar",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        public async Task<List<BookOutputModel>> GetByAuthorAsync(int authorId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@AuthorId", authorId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetByAuthor",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookOutputModel> rows = await connection.QueryAsync<BookOutputModel>(command);
                List<BookOutputModel> books = rows.ToList();

                await AddSpecsAsync(books, cancellationToken);

                return books;
            }
        }

        // genres / languages: the stored procedure takes them as comma-separated text; an empty list means "no filter".
        public async Task<BookSearchOutputModel> SearchAsync(string? query, List<string> genres, List<string> languages, int? authorId, decimal? minPrice, decimal? maxPrice, bool inStockOnly, string? sort, int page, int pageSize, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Query", query);
                parameters.Add("@Genres", JoinOrNull(genres));
                parameters.Add("@Languages", JoinOrNull(languages));
                parameters.Add("@AuthorId", authorId);
                parameters.Add("@MinPrice", minPrice);
                parameters.Add("@MaxPrice", maxPrice);
                parameters.Add("@InStockOnly", inStockOnly);
                parameters.Add("@Sort", sort);
                parameters.Add("@Page", page);
                parameters.Add("@PageSize", pageSize);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Search",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                // The procedure returns two result sets: the total count, then the page of books.
                using (SqlMapper.GridReader reader = await connection.QueryMultipleAsync(command))
                {
                    // Page and PageSize come back from the procedure because it corrects out-of-range values.
                    BookSearchOutputModel result = await reader.ReadSingleAsync<BookSearchOutputModel>();

                    IEnumerable<BookOutputModel> rows = await reader.ReadAsync<BookOutputModel>();
                    result.Items = rows.ToList();

                    await AddSpecsAsync(result.Items, cancellationToken);

                    return result;
                }
            }
        }

        public async Task<BookFiltersOutputModel> GetFiltersAsync(CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_GetFilters",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                // Three result sets, read in the order the procedure selects them: prices, genres, languages.
                using (SqlMapper.GridReader reader = await connection.QueryMultipleAsync(command))
                {
                    BookFiltersOutputModel filters = await reader.ReadSingleAsync<BookFiltersOutputModel>();

                    IEnumerable<string> genres = await reader.ReadAsync<string>();
                    filters.Genres = genres.ToList();

                    IEnumerable<string> languages = await reader.ReadAsync<string>();
                    filters.Languages = languages.ToList();

                    return filters;
                }
            }
        }

        // Returns the new Id. Specs travel as JSON text; the procedure saves book + specs in one transaction.
        public async Task<int> InsertAsync(CreateBookRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Title", request.Title);
                parameters.Add("@AuthorId", request.AuthorId);
                parameters.Add("@Price", request.Price);
                parameters.Add("@OldPrice", request.OldPrice);
                parameters.Add("@Stock", request.Stock);
                parameters.Add("@Image", request.Image);
                parameters.Add("@Description", request.Description);
                parameters.Add("@Genre", request.Genre);
                parameters.Add("@Language", request.Language);
                parameters.Add("@Specs", JsonSerializer.Serialize(request.Specs));

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Insert",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int newId = await connection.ExecuteScalarAsync<int>(command);

                return newId;
            }
        }

        // Returns false when the book does not exist.
        public async Task<bool> UpdateAsync(int id, UpdateBookRequestModel request, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);
                parameters.Add("@Title", request.Title);
                parameters.Add("@AuthorId", request.AuthorId);
                parameters.Add("@Price", request.Price);
                parameters.Add("@OldPrice", request.OldPrice);
                parameters.Add("@Stock", request.Stock);
                parameters.Add("@Image", request.Image);
                parameters.Add("@Description", request.Description);
                parameters.Add("@Genre", request.Genre);
                parameters.Add("@Language", request.Language);
                parameters.Add("@Specs", JsonSerializer.Serialize(request.Specs));

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Update",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        // Returns false when the book does not exist.
        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@Id", id);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Books_Delete",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                int affectedRows = await connection.ExecuteScalarAsync<int>(command);

                return affectedRows > 0;
            }
        }

        // One call loads the specs of all given books (instead of one call per book), then each spec is put on its book.
        private async Task AddSpecsAsync(List<BookOutputModel> books, CancellationToken cancellationToken)
        {
            if (books.Count == 0)
            {
                return;
            }

            Dictionary<int, BookOutputModel> booksById = new Dictionary<int, BookOutputModel>();
            List<string> ids = new List<string>();

            foreach (BookOutputModel book in books)
            {
                booksById[book.Id] = book;
                ids.Add(book.Id.ToString());
            }

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@BookIds", string.Join(",", ids));

                CommandDefinition command = new CommandDefinition(
                    "dbo.BookSpecs_GetByBookIds",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                IEnumerable<BookSpecRowModel> rows = await connection.QueryAsync<BookSpecRowModel>(command);

                foreach (BookSpecRowModel row in rows)
                {
                    BookSpecOutputModel spec = new BookSpecOutputModel();
                    spec.Label = row.Label;
                    spec.Value = row.Value;

                    booksById[row.BookId].Specs.Add(spec);
                }
            }
        }

        private string? JoinOrNull(List<string> values)
        {
            if (values.Count == 0)
            {
                return null;
            }

            return string.Join(",", values);
        }
    }
}
