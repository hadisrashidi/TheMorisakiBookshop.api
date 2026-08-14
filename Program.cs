using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            builder.Services.AddSingleton<IBooksRepository, JsonBooksRepository>();
            builder.Services.AddSingleton<IAuthorsRepository, JsonAuthorsRepository>();

            // "AllowedOrigins" comes from appsettings — falls back to the
            // Angular dev server if nothing is configured, rather than
            // wildcarding to any origin.
            var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                ?? new[] { "http://localhost:4200" };

            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowFrontendOrigin", policy =>
                {
                    policy.WithOrigins(allowedOrigins)
                          .AllowAnyHeader()
                          .AllowAnyMethod();
                });
            });

            var app = builder.Build();

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }
            else
            {
                app.UseExceptionHandler(handler =>
                {
                    handler.Run(async context =>
                    {
                        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                        context.Response.ContentType = "application/json";
                        await context.Response.WriteAsJsonAsync(new { message = "An unexpected error occurred." });
                    });
                });
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();

            app.UseCors("AllowFrontendOrigin");

            app.MapControllers();

            app.Run();
        }
    }
}