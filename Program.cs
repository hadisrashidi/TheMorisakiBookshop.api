using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers()
                .ConfigureApiBehaviorOptions(options =>
                {
                    // Validation errors use the same envelope as every other response.
                    options.InvalidModelStateResponseFactory = context =>
                    {
                        CustomActionResult result = new CustomActionResult();
                        result.IsSuccess = false;
                        result.Message = "The request is not valid.";

                        foreach (KeyValuePair<string, ModelStateEntry> entry in context.ModelState)
                        {
                            foreach (ModelError error in entry.Value.Errors)
                            {
                                result.Errors.Add(error.ErrorMessage);
                            }
                        }

                        return new BadRequestObjectResult(result);
                    };
                });
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            builder.Services.AddSingleton<IBooksRepository, JsonBooksRepository>();
            builder.Services.AddSingleton<IAuthorsRepository, JsonAuthorsRepository>();
            builder.Services.AddSingleton<IReviewsRepository, JsonReviewsRepository>();

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

            // Unexpected exceptions become a 500 with the standard envelope (also in
            // Development, so the Angular app sees the same shape everywhere).
            app.UseExceptionHandler(handler =>
            {
                handler.Run(async context =>
                {
                    CustomActionResult result = new CustomActionResult();
                    result.IsSuccess = false;
                    result.Message = "An unexpected error occurred.";

                    context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                    await context.Response.WriteAsJsonAsync(result);
                });
            });

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseCors("AllowFrontendOrigin");

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}