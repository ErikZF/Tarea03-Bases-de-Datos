using System;
using Microsoft.AspNetCore.Mvc;
using VacacionesAPI.DTOs;
using VacacionesAPI.Interfaces;

namespace PlanillaAPI;

public class EmpleadoEndpoint
{


    public static void MapearEmpleadoEndpoints(WebApplication app)
    {

        app.MapGet("/api/empleados", async (string? filtro, IEmpleadoService empleadoService) =>
            {
                filtro ??= "";
                var (empleados, error) = await empleadoService.ListarAsync(filtro);

                if (error is not null)
                    return Results.BadRequest(new { mensaje = error });

                return Results.Ok(empleados);
            });

        app.MapGet("/api/empleados/{id}", async (int id, IEmpleadoService empleadoService) =>
        {
            var (empleado, error) = await empleadoService.ConsultarAsync(id);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok(empleado);
        });

        app.MapGet("/api/empleados/puestos", async (IEmpleadoService empleadoService) =>
        {
            var puestos = await empleadoService.ObtenerPuestosAsync();
            return Results.Ok(puestos);
        });

        app.MapPost("/api/empleados", async (InsertarEmpleadoDTO dto, int userId, string ip, IEmpleadoService empleadoService) =>
        {
            string? error = await empleadoService.InsertarAsync(dto, userId, ip);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok();
        });

        app.MapPut("/api/empleados/{id}", async (int id, ActualizarEmpleadoDTO dto, int userId, string ip, IEmpleadoService empleadoService) =>
        {
            string? error = await empleadoService.ActualizarAsync(id, dto, userId, ip);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok();
        });

        app.MapDelete("/api/empleados/{id}", async (int id, int userId, string ip, IEmpleadoService empleadoService) =>
        {
            string? error = await empleadoService.EliminarAsync(id, userId, ip);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok();
        });



    }



}
