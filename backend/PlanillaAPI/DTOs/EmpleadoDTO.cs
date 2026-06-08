namespace VacacionesAPI.DTOs;

public class EmpleadoDTO
{
    public int Id { get; set; }
    public string ValorDocumentoIdentidad { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public int IdPuesto { get; set; }
    public string NombreDepartamento { get; set; } = string.Empty;
    public int IdTipoDocumento { get; set; }
    public string CuentaBancaria { get; set; } = string.Empty;
    public string NombrePuesto { get; set; } = string.Empty;
    public DateTime FechaContratacion { get; set; }
    public bool Activo { get; set; }

}
