using System.Data;
using Dapper;
using VacacionesAPI.DTOs;
using VacacionesAPI.Interfaces;

namespace VacacionesAPI.Services;

public class PlanillaService : IPlanillaService
{
    private readonly IDbConnection _db;

    public PlanillaService(IDbConnection db)
    {
        _db = db;
    }
    public async Task<(IEnumerable<PlanillaSemanalDTO> planillasSemanales, string? Error)> ConsultarHistorialSemanalAsync(int idEmpleado, int QSemanas)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", idEmpleado);
        parametros.Add("@inCantSemanas", QSemanas);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var planillas = await _db.QueryAsync<PlanillaSemanalDTO>("dbo.spConsultarPlanillaSemanal", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<PlanillaSemanalDTO>(), error);
        }

        return (planillas, null);
    }








    public async Task<(IEnumerable<DeduccionDTO?> deduccionesSemanales, string? Error)> ConsultarDeduccionesSemanalesAsync(int idEmpleado, int idPlanillaSemanal)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", idEmpleado);
        parametros.Add("@inIdPlanillaSemanal", idPlanillaSemanal);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var deducciones = await _db.QueryAsync<DeduccionDTO>("dbo.spConsultarDeduccionesSemanal", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<DeduccionDTO>(), error);
        }

        return (deducciones, null);
    }








    public async Task<(IEnumerable<MarcaAsistenciaDTO?> asistencias, string? Error)> ConsultarAsistenciaDiariaAsync(int idPlanillaSemanal)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdPlanillaSemanal", idPlanillaSemanal);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var asistencias = await _db.QueryAsync<MarcaAsistenciaDTO>("dbo.spDetallePlanillaSemanal", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<MarcaAsistenciaDTO>(), error);
        }

        return (asistencias, null);
    }






    public async Task<(IEnumerable<PlanillaMensualDTO?> planillasMensuales, string? Error)> ConsultarHistorialMensualAsync(int idEmpleado)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", idEmpleado);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var planillas = await _db.QueryAsync<PlanillaMensualDTO>("dbo.spConsultarPlanillaMensual", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<PlanillaMensualDTO>(), error);
        }

        return (planillas, null);
    }






    public async Task<(IEnumerable<DeduccionDTO?> deduccionesMensuales, string? Error)> ConsultarDeduccionesMensualesAsync(int idEmpleado, int inIdPlanillaMensual)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdEmpleado", idEmpleado);
        parametros.Add("@inIdPlanillaMensual", inIdPlanillaMensual);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var deducciones = await _db.QueryAsync<DeduccionDTO>("dbo.spDetallePlanillaMensual", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {

            string? error = await ConsultarErrorAsync(resultCode);
            return (Enumerable.Empty<DeduccionDTO>(), error);
        }

        return (deducciones, null);
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
