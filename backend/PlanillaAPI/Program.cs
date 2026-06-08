using System.Data;
using Microsoft.Data.SqlClient;
using PlanillaAPI;
using Scalar.AspNetCore;
using VacacionesAPI.Interfaces;
using VacacionesAPI.Services;

var builder = WebApplication.CreateBuilder(args);

string connectionString = builder.Configuration.GetConnectionString("DockerConnection")
    ?? throw new InvalidOperationException("Connection string not found.");


builder.Services.AddTransient<IDbConnection>(_ => new SqlConnection(connectionString));
builder.Services.AddScoped<IEmpleadoService, EmpleadoService>();
builder.Services.AddOpenApi();


var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}



app.UseHttpsRedirection();

EmpleadoEndpoint.MapearEmpleadoEndpoints(app);

app.Run();
