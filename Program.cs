using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using TheMorisakiBookshop.Middleware;
using TheMorisakiBookshop.Models;
using Microsoft.IdentityModel.Tokens;
using TheMorisakiBookshop.Repositories;
using TheMorisakiBookshop.Security;

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

            builder.Services.AddScoped<BooksRepository>();
            builder.Services.AddScoped<AuthorsRepository>();
            builder.Services.AddScoped<ReviewsRepository>();
            builder.Services.AddScoped<UsersRepository>();
            builder.Services.AddScoped<OtpCodesRepository>();

            builder.Services.AddScoped<OtpService>();
            builder.Services.AddScoped<SmsSender>();
            builder.Services.AddScoped<PasswordService>();
            builder.Services.AddScoped<JwtTokenService>();

            // The signing key is a secret: Development gets a throwaway one from
            // appsettings.Development.json, production must set Jwt__Key as an environment variable.
            string jwtKey = builder.Configuration["Jwt:Key"] ?? "";

            if (jwtKey.Length < 32)
            {
                throw new InvalidOperationException("Jwt:Key is missing or shorter than 32 characters.");
            }

            if (builder.Configuration.GetValue<bool>("Sms:ShowCodeInResponse") && builder.Environment.IsDevelopment() == false)
            {
                throw new InvalidOperationException("Sms:ShowCodeInResponse may only be true in Development.");
            }

            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = builder.Configuration["Jwt:Issuer"],
                        ValidateAudience = true,
                        ValidAudience = builder.Configuration["Jwt:Audience"],
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                        ClockSkew = TimeSpan.FromMinutes(1)
                    };

                    // 401 / 403 use the same envelope as every other response.
                    options.Events = new JwtBearerEvents
                    {
                        OnChallenge = async context =>
                        {
                            context.HandleResponse();
                            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                            await context.Response.WriteAsJsonAsync(new CustomActionResult
                            {
                                IsSuccess = false,
                                Message = "Please log in."
                            });
                        },
                        OnForbidden = async context =>
                        {
                            context.Response.StatusCode = StatusCodes.Status403Forbidden;
                            await context.Response.WriteAsJsonAsync(new CustomActionResult
                            {
                                IsSuccess = false,
                                Message = "You are not allowed to do this."
                            });
                        }
                    };
                });
            builder.Services.AddAuthorization();

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

            // First in the pipeline, so it catches exceptions from everything after it.
            // Logs the exception and answers 500 with the standard envelope.
            app.UseMiddleware<ExceptionHandlingMiddleware>();

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseCors("AllowFrontendOrigin");

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
