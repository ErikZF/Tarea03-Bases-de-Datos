namespace VacacionesAPI.DTOs;

public class InsertarEmpleadoDTO
{
    public string ValorDocumentoIdentidad { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public int IdPuesto { get; set; }
    public int IdDepartamento { get; set; }
    public int IdTipoDocumento { get; set; }
    public string CuentaBancaria { get; set; } = string.Empty;

}
