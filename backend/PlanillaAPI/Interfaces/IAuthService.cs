using System;
using VacacionesAPI.DTOs;
namespace VacacionesAPI.Interfaces;

public interface IAuthService
{
    Task<(LoginResponseDTO? Response, string? Error)> LoginAsync(LoginRequestDTO dto);
    Task<string?> LogoutAsync(int userId, string ip);
}
