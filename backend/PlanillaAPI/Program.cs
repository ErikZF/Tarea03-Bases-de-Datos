using System.Data;
using Microsoft.Data.SqlClient;
using PlanillaAPI;
using Scalar.AspNetCore;
using VacacionesAPI.Endpoints;
using VacacionesAPI.Interfaces;
using VacacionesAPI.Services;

var builder = WebApplication.CreateBuilder(args);

string connectionString = builder.Configuration.GetConnectionString("DockerConnection")
    ?? throw new InvalidOperationException("Connection string not found.");


builder.Services.AddTransient<IDbConnection>(_ => new SqlConnection(connectionString));
builder.Services.AddScoped<IEmpleadoService, EmpleadoService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddOpenApi();


builder.Services.AddCors(options =>
{
    options.AddPolicy("PermitirAngular", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();


app.UseCors("PermitirAngular");

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}



app.UseHttpsRedirection();

EmpleadoEndpoint.MapearEmpleadoEndpoints(app);
AuthEndpoints.MapAuthEndpoints(app);

app.Run();
