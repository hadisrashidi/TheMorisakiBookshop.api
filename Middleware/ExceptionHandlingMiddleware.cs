using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Middleware
{
    // Catches every unhandled exception of a request, logs it with its full stack trace,
    // and answers with the standard envelope (HTTP 500).
    // In Development the envelope also carries the exception type and message in "errors".
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;
        private readonly IHostEnvironment _environment;

        public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger, IHostEnvironment environment)
        {
            _next = next;
            _logger = logger;
            _environment = environment;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception exception)
            {
                // The browser closed the request: nobody is waiting for an answer and it is not an error.
                if (context.RequestAborted.IsCancellationRequested)
                {
                    return;
                }

                _logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);

                // Too late to change the response: rethrow so the server closes the connection.
                if (context.Response.HasStarted)
                {
                    throw;
                }

                await WriteErrorResponseAsync(context, exception);
            }
        }

        private async Task WriteErrorResponseAsync(HttpContext context, Exception exception)
        {
            CustomActionResult result = new CustomActionResult();
            result.IsSuccess = false;
            result.Message = "خطای غیرمنتظره‌ای رخ داد. لطفاً دوباره تلاش کنید.";

            if (_environment.IsDevelopment())
            {
                result.Errors.Add(exception.GetType().Name + ": " + exception.Message);
            }

            context.Response.Clear();
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsJsonAsync(result);
        }
    }
}
