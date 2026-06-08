using System;

namespace VacacionesAPI.DTOs;

public class ErrorDTO
{
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
}