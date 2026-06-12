using System.Data;
using Dapper;
using VacacionesAPI.DTOs;
using VacacionesAPI.Interfaces;

namespace VacacionesAPI.Services;

public class EmpleadoService : IEmpleadoService
{
    private readonly IDbConnection _db;

    public EmpleadoService(IDbConnection db)
    {
        _db = db;
    }

    public async Task<(IEnumerable<EmpleadoDTO> Empleados, string? Error)> ListarAsync(string? filtro)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inFiltro", filtro);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var empleados = await _db.QueryAsync<EmpleadoDTO>("dbo.spListarEmpleados", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<EmpleadoDTO>(), error);
        }

        return (empleados, null);
    }

    public async Task<(EmpleadoDTO? Empleado, string? Error)> ConsultarAsync(int id)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inId", id);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var empleado = await _db.QueryFirstOrDefaultAsync<EmpleadoDTO>("dbo.spConsultarEmpleado", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {
            string? error = await ConsultarErrorAsync(resultCode);
            return (null, error);
        }

        return (empleado, null);
    }

    public async Task<string?> InsertarAsync(InsertarEmpleadoDTO dto, int userId, string ip)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inValorDocIdentidad", dto.ValorDocumentoIdentidad);

        parametros.Add("@inNombre", dto.Nombre);

        parametros.Add("@inIdPuesto", dto.IdPuesto);
        parametros.Add("@inIdUsuario", userId);

        parametros.Add("@inCuentaBancaria", dto.CuentaBancaria);
        parametros.Add("@inIP", ip);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _db.ExecuteAsync("dbo.spInsertarEmpleado", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
            return await ConsultarErrorAsync(resultCode);

        return null;
    }

    public async Task<string?> ActualizarAsync(int id, ActualizarEmpleadoDTO dto, int userId, string ip)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", id);
        parametros.Add("@inValorDocIdentidad", dto.ValorDocumentoIdentidad);
        parametros.Add("@inNombre", dto.Nombre);
        parametros.Add("@inIdDepartamento", dto.IdDepartamento);
        parametros.Add("@inCuentaBancaria", dto.CuentaBancaria);
        parametros.Add("@inIdPuesto", dto.IdPuesto);
        parametros.Add("@inIdUsuario", userId);
        parametros.Add("@inIP", ip);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _db.ExecuteAsync("dbo.spActualizarEmpleado", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
            return await ConsultarErrorAsync(resultCode);

        return null;
    }

    public async Task<string?> EliminarAsync(int id, int userId, string ip)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", id);
        parametros.Add("@inIdUsuario", userId);
        parametros.Add("@inIP", ip);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _db.ExecuteAsync("dbo.spEliminarEmpleado", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
            return await ConsultarErrorAsync(resultCode);

        return null;
    }

    public async Task<IEnumerable<PuestoDTO>> ObtenerPuestosAsync()
    {
        var parametros = new DynamicParameters();
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var puestos = await _db.QueryAsync<PuestoDTO>("dbo.spObtenerPuestos", parametros, commandType: CommandType.StoredProcedure);

        return puestos;
    }

    private async Task<string?> ConsultarErrorAsync(int codigo)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inCodigoError", codigo.ToString());
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var resultado = await _db.QueryFirstOrDefaultAsync<ErrorDTO>(
            "dbo.spConsultarError",
            parametros,
            commandType: CommandType.StoredProcedure
        );
        return resultado?.Descripcion ?? "Error desconocido";
    }

}
