
using GradesServer.Data;
using GradesServer.Services;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;

namespace GradesServer
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("The connection string 'DefaultConnection' is not configured.");
            }

            builder.Services.AddDbContext<GradesDbContext>(options =>
                options.UseSqlServer(connectionString));

            builder.Services.AddHealthChecks()
                .AddSqlServer(connectionString);

            builder.Services.AddControllers();
            builder.Services.AddScoped<IReportService, ReportService>();
            builder.Services.AddScoped<IQuestionService, QuestionService>();

            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();
            app.UseAuthorization();
            app.MapControllers();
            app.MapHealthChecks("/health", new HealthCheckOptions
            {
                ResponseWriter = async (context, report) =>
                {
                    context.Response.ContentType = "application/json";

                    var result = new
                    {
                        status = report.Status.ToString(),
                        errors = report.Entries.Select(e => new {
                            key = e.Key,
                            status = e.Value.Status.ToString(),
                            description = e.Value.Description,
                            exception = e.Value.Exception?.Message
                        })
                    };

                    await context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(result));
                }
            });

            app.Run();
        }
    }
}
