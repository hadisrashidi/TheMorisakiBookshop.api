using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;

namespace TheMorisakiBookshop.Repositories
{
    public class OrdersRepository
    {
        private readonly string _connectionString;

        public OrdersRepository(IConfiguration configuration)
        {
            string? connectionString = configuration.GetConnectionString("Bookshop");

            if (connectionString == null)
            {
                throw new InvalidOperationException("Connection string 'Bookshop' is missing in appsettings.");
            }

            _connectionString = connectionString;
        }

        // The lines travel as JSON text (like the old book specs); the procedure does stock check, stock decrease and insert in one transaction.
        public async Task<OrderPlacedModel> PlaceAsync(int userId, PlaceOrderRequestModel request, CancellationToken cancellationToken)
        {
            string linesJson = JsonSerializer.Serialize(request.Lines);

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@RecipientName", request.RecipientName.Trim());
                parameters.Add("@RecipientMobile", request.RecipientMobile);
                parameters.Add("@Address", request.Address.Trim());
                parameters.Add("@PostalCode", request.PostalCode);
                parameters.Add("@ShippingMethodId", request.ShippingMethodId);
                parameters.Add("@City", request.City.Trim());
                parameters.Add("@Lines", linesJson);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Orders_Place",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                OrderPlacedModel placed = await connection.QuerySingleAsync<OrderPlacedModel>(command);

                return placed;
            }
        }

        // Result set 1 = the orders, 2 = all their lines, 3 = all their status history; each row is put on its order.
        public async Task<List<OrderOutputModel>> GetByUserIdAsync(int userId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Orders_GetByUserId",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                using (SqlMapper.GridReader reader = await connection.QueryMultipleAsync(command))
                {
                    IEnumerable<OrderOutputModel> orderRows = await reader.ReadAsync<OrderOutputModel>();
                    List<OrderOutputModel> orders = orderRows.ToList();

                    Dictionary<int, OrderOutputModel> ordersById = new Dictionary<int, OrderOutputModel>();

                    foreach (OrderOutputModel order in orders)
                    {
                        ordersById[order.Id] = order;
                    }

                    IEnumerable<OrderLineOutputModel> lines = await reader.ReadAsync<OrderLineOutputModel>();

                    foreach (OrderLineOutputModel line in lines)
                    {
                        ordersById[line.OrderId].Lines.Add(line);
                    }

                    IEnumerable<OrderStatusHistoryOutputModel> history = await reader.ReadAsync<OrderStatusHistoryOutputModel>();

                    foreach (OrderStatusHistoryOutputModel step in history)
                    {
                        ordersById[step.OrderId].History.Add(step);
                    }

                    return orders;
                }
            }
        }

        // A customer cancels her own order (only while it is PendingPayment; the procedure checks both).
        public async Task<OrderCancelResultModel> CancelMineAsync(int userId, int orderId, CancellationToken cancellationToken)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("@UserId", userId);
                parameters.Add("@Id", orderId);

                CommandDefinition command = new CommandDefinition(
                    "dbo.Orders_CancelMine",
                    parameters,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken);

                OrderCancelResultModel result = await connection.QuerySingleAsync<OrderCancelResultModel>(command);

                return result;
            }
        }
    }
}
