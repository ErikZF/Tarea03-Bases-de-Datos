using System;
using VacacionesAPI.DTOs;
using VacacionesAPI.Interfaces;

namespace VacacionesAPI.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(WebApplication app)
    {
        app.MapPost("/api/auth/login", async (LoginRequestDTO dto, IAuthService authService, HttpContext context) =>
        {
            dto.PostInIP = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

            var (response, error) = await authService.LoginAsync(dto);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok(response);
        });

        app.MapPost("/api/auth/logout", async (HttpContext context, IAuthService authService) =>
        {
            int userId = int.Parse(context.Request.Headers["X-User-Id"].ToString());
            string ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

            string? error = await authService.LogoutAsync(userId, ip);

            if (error is not null)
                return Results.BadRequest(new { mensaje = error });

            return Results.Ok();
        });
    }
}