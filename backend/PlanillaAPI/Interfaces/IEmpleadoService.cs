using VacacionesAPI.DTOs;

namespace VacacionesAPI.Interfaces;

public interface IEmpleadoService
{
    Task<(IEnumerable<EmpleadoDTO> Empleados, string? Error)> ListarAsync(string filtro);
    Task<(EmpleadoDTO? Empleado, string? Error)> ConsultarAsync(int id);
    Task<string?> InsertarAsync(InsertarEmpleadoDTO dto, int userId, string ip);
    Task<string?> ActualizarAsync(int id, ActualizarEmpleadoDTO dto, int userId, string ip);
    Task<string?> EliminarAsync(int id, int userId, string ip);
    Task<IEnumerable<PuestoDTO>> ObtenerPuestosAsync();
}