namespace TheMorisakiBookshop.Security
{
    // MOCK: there is no SMS provider yet, so the code is only written to the log.
    // Replace the body with the provider's API call when one is chosen (BACKLOG task 11).
    public class SmsSender
    {
        private readonly ILogger<SmsSender> _logger;

        public SmsSender(ILogger<SmsSender> logger)
        {
            _logger = logger;
        }

        public Task SendAsync(string mobile, string message, CancellationToken cancellationToken)
        {
            _logger.LogWarning("MOCK SMS to {Mobile}: {Message}", mobile, message);

            return Task.CompletedTask;
        }
    }
}
