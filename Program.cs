using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using TheMorisakiBookshop.Middleware;
using TheMorisakiBookshop.Models;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using TheMorisakiBookshop.Repositories;
using TheMorisakiBookshop.Security;
using Microsoft.Extensions.FileProviders;

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
                        result.Message = "اطلاعات واردشده معتبر نیست.";

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
            builder.Services.AddSwaggerGen(options =>
            {
                // Adds the "Authorize" button: paste the token from VerifyOtp (without the word "Bearer").
                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header
                });

                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
                        },
                        new List<string>()
                    }
                });
            });

            builder.Services.AddScoped<BooksRepository>();
            builder.Services.AddScoped<AuthorsRepository>();
            builder.Services.AddScoped<ReviewsRepository>();
            builder.Services.AddScoped<UsersRepository>();
            builder.Services.AddScoped<OrdersRepository>();
            builder.Services.AddScoped<AddressesRepository>();
            builder.Services.AddScoped<CartRepository>();
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
                                Message = "لطفاً وارد حساب خود شوید."
                            });
                        },
                        OnForbidden = async context =>
                        {
                            context.Response.StatusCode = StatusCodes.Status403Forbidden;
                            await context.Response.WriteAsJsonAsync(new CustomActionResult
                            {
                                IsSuccess = false,
                                Message = "اجازه انجام این کار را ندارید."
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

            // Cover / author images uploaded in the admin panel are public files at /uploads/...
            // The admin API writes them; both APIs must point Uploads:RootPath to the same folder.
            string uploadsConfigured = builder.Configuration["Uploads:RootPath"] ?? "../uploads";
            string uploadsPath = Path.Combine(builder.Environment.ContentRootPath, uploadsConfigured);
            Directory.CreateDirectory(uploadsPath);
            app.Logger.LogInformation("Uploads folder (must be the same folder the admin API writes to): {Path}", Path.GetFullPath(uploadsPath));

            app.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(Path.GetFullPath(uploadsPath)),
                RequestPath = "/uploads"
            });

            app.UseCors("AllowFrontendOrigin");

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
