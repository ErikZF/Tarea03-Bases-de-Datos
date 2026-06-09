using System.Data;
using Dapper;
using VacacionesAPI.DTOs;
using VacacionesAPI.Interfaces;

namespace VacacionesAPI.Services;

public class AuthService : IAuthService
{
    private readonly IDbConnection _db;

    public AuthService(IDbConnection db)
    {
        _db = db;
    }

    public async Task<(LoginResponseDTO? Response, string? Error)> LoginAsync(LoginRequestDTO dto)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inUsername", dto.Username);
        parametros.Add("@inPassword", dto.Password);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        LoginResponseDTO? res = await _db.QueryFirstOrDefaultAsync<LoginResponseDTO>("dbo.spLogin", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
        {
            string? error = await ConsultarErrorAsync(resultCode);
            return (null, error);
        }

        return (res, null);
    }

    public async Task<string?> LogoutAsync(int userId, string ip)
    {
        var parametros = new DynamicParameters();
        parametros.Add("@inIdUsuario", userId);
        parametros.Add("@inIP", ip);
        parametros.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _db.ExecuteAsync("dbo.spLogout", parametros, commandType: CommandType.StoredProcedure);

        int resultCode = parametros.Get<int>("@outResultCode");

        if (resultCode != 0)
            return await ConsultarErrorAsync(resultCode);

        return null;
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