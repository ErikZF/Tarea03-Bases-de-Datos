using System;

namespace VacacionesAPI.DTOs;

public class LoginRequestDTO
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string PostInIP { get; set; } = string.Empty;


}
