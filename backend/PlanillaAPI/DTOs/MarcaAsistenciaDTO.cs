
namespace VacacionesAPI.DTOs;

public class MarcaAsistenciaDTO
{
    public DateTime Fecha { get; set; }
    public DateTime HoraEntrada { get; set; }
    public DateTime HoraSalida { get; set; }
    public int HorasOrdinarias { get; set; }
    public decimal MontoOrdinario { get; set; }
    public int HorasExtra { get; set; }
    public decimal MontoExtra { get; set; }
    public int HorasDobles { get; set; }
    public decimal MontoDobles { get; set; }
}
