// --Detalle por dia, hora entrada, salida y movimientos generados
//     SELECT
//         MA.Fecha
//         , MA.HoraEntrada
//         , MA.HoraSalida
//         , TM.Nombre AS TipoMovimiento
//         , TM.Accion
//         , MP.Monto
//         , MP.NuevoSaldo
//     FROM dbo.Comprobante AS C
//     INNER JOIN dbo.ComprobanteHora AS CH ON (CH.idComprobante = C.id)
//     INNER JOIN dbo.MarcaAsistencia AS MA ON (MA.id = CH.idMarcaAsistencia)
//     INNER JOIN dbo.MovPlanilla AS MP ON (MP.idComprobante = C.id)
//     INNER JOIN dbo.TipoMovimiento AS TM ON (TM.id = MP.idTipoMovimiento)
//     WHERE (C.idPlanillaSemanal = @inIdPlanillaSemanal)
//         AND (C.Tipo = 'H')
//     ORDER BY MA.Fecha, MA.HoraEntrada, TM.id;

public class MarcaAsistenciaDTO
{

    public DateOnly Fecha { get; set; }
    public DateTime HoraEntrada { get; set; }
    public DateTime HoraSalida { get; set; }
    public string TipoMovimiento { get; set; } = string.Empty;
    public string Accion { get; set; } = string.Empty;
    public int Monto { get; set; }
    public int NuevoSaldo { get; set; }
}
