using System;

namespace VacacionesAPI.DTOs;

public class LoginResponseDTO
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;

    public int Tipo { get; set; }

    public int IdEmpleado { get; set; }

}

