
namespace VacacionesAPI.DTOs;

public class PlanillaMensualDTO
{
    public int id { get; set; }
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    public float SalarioBruto { get; set; }
    public float TotalDeducciones { get; set; }
    public float SalarioNeto { get; set; }
}