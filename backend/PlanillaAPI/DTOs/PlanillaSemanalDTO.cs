
namespace VacacionesAPI.DTOs;

public class PlanillaSemanalDTO
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    public string RangoFechas { get; set; } = string.Empty;
    public float SalarioBruto { get; set; }
    public float TotalDeducciones { get; set; }
    public float SalarioNeto { get; set; }
    public int HorasOrdinarias { get; set; }
    public int HorasExtraNormal { get; set; }
    public int HorasExtraDoble { get; set; }
}