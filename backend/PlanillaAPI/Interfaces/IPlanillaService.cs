using VacacionesAPI.DTOs;

namespace VacacionesAPI.Interfaces;

public interface IPlanillaService
{
    Task<(IEnumerable<PlanillaSemanalDTO> planillasSemanales, string? Error)> ConsultarHistorialSemanalAsync(int idEmpleado, int QSemanas);
    Task<(IEnumerable<DeduccionDTO?> deduccionesSemanales, string? Error)> ConsultarDeduccionesSemanalesAsync(int idEmpleado, int idPlanillaSemanal);
    Task<(IEnumerable<MarcaAsistenciaDTO?> asistencias, string? Error)> ConsultarAsistenciaDiariaAsync(int idPlanillaSemanal);
    Task<(IEnumerable<PlanillaMensualDTO?> planillasMensuales, string? Error)> ConsultarHistorialMensualAsync(int idEmpleado);
    Task<(IEnumerable<DeduccionDTO?> deduccionesMensuales, string? Error)> ConsultarDeduccionesMensualesAsync(int idEmpleado, int inIdPlanillaMensual);
}