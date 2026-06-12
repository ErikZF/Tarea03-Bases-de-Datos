
using Microsoft.AspNetCore.Mvc;
using VacacionesAPI.Interfaces;

namespace PlanillaAPI.Endpoints
{
    public static class PlanillaEndpoints
    {
        public static void MapearPlanillaEndpoints(WebApplication app)
        {
            var group = app.MapGroup("/api/planilla");

            group.MapGet("/semanal/{empleadoId:int}", async (
                int empleadoId,
                [FromQuery] int? limite,
                IPlanillaService planillaService) =>
            {
                int semanasAConsultar = limite ?? 10;

                var (planillas, error) = await planillaService.ConsultarHistorialSemanalAsync(empleadoId, semanasAConsultar);

                if (error != null)
                {
                    return Results.BadRequest(new { mensaje = error });
                }

                return Results.Ok(planillas);
            });


            group.MapGet("/semanal/{planillaSemanalId:int}/deducciones", async (
                int planillaSemanalId,
                [FromQuery] int empleadoId,
                IPlanillaService planillaService) =>
            {
                var (deducciones, error) = await planillaService.ConsultarDeduccionesSemanalesAsync(empleadoId, planillaSemanalId);

                if (error != null)
                {
                    return Results.BadRequest(new { mensaje = error });
                }

                return Results.Ok(deducciones);
            });

            group.MapGet("/semanal/{planillaSemanalId:int}/asistencia", async (
                int planillaSemanalId,
                IPlanillaService planillaService) =>
            {
                var (asistencias, error) = await planillaService.ConsultarAsistenciaDiariaAsync(planillaSemanalId);

                if (error != null)
                {
                    return Results.BadRequest(new { mensaje = error });
                }

                return Results.Ok(asistencias);
            });

            group.MapGet("/mensual/{empleadoId:int}", async (
                int empleadoId,
                IPlanillaService planillaService) =>
            {
                var (planillas, error) = await planillaService.ConsultarHistorialMensualAsync(empleadoId);

                if (error != null)
                {
                    return Results.BadRequest(new { mensaje = error });
                }

                return Results.Ok(planillas);
            });


            group.MapGet("/mensual/{planillaMensualId:int}/deducciones", async (
                int planillaMensualId,
                [FromQuery] int empleadoId,
                IPlanillaService planillaService) =>
            {
                var (deducciones, error) = await planillaService.ConsultarDeduccionesMensualesAsync(empleadoId, planillaMensualId);

                if (error != null)
                {
                    return Results.BadRequest(new { mensaje = error });
                }

                return Results.Ok(deducciones);
            });
        }
    }
}