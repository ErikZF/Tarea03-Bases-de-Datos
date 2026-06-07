-- init.sql
-- Punto de entrada unico para inicializar DBPlanilla
-- Ejecutar desde la raiz de /scripts con:
--   sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i init.sql

--#####################################################################
-- CREAR Y USAR DB
--#####################################################################

:r /scripts/Migrations/00_create_database.sql
GO

--#####################################################################
-- CREAR TABLAS (incluye DBError)
--#####################################################################

:r /scripts/Migrations/01_create_tables.sql
GO


--#####################################################################
-- STORED PROCEDURES
--#####################################################################

:r /scripts/StoredProcedures/Error/spInsertarError.sql
GO




:r /scripts/StoredProcedures/Planilla/spAperturaSemana.sql
GO

:r /scripts/StoredProcedures/Planilla/spCierreSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarPlanillaSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarDeduccionesSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spDetallePlanillaMensual.sql
GO

:r /scripts/StoredProcedures/Planilla/spDetallePlanillaSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spProcesarMarcaAsistencia.sql
GO




:r /scripts/StoredProcedures/Empleado/spListarEmpleados.sql
GO

:r /scripts/StoredProcedures/Empleado/spInsertarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spEliminarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spActualizarEmpleado.sql
GO




:r /scripts/StoredProcedures/Auth/spInsertarBitacoraEvento.sql
GO

:r /scripts/StoredProcedures/Auth/spLogin.sql
GO

--#####################################################################
-- TRIGGERS
--#####################################################################

:r /scripts/Trigger/triggerAsociarEmpleadoDeducciones.sql
GO


--#####################################################################
-- LLENAR CATALOGOS CON XML
--#####################################################################

:r /scripts/Data/spCargarCatalogosXML.sql
GO

:r /scripts/ETL/spETLCargaOperacionEmpleado.sql
GO



DECLARE @MiXML XML;
DECLARE @ResultadoCodigo INT;

SET @MiXML = 
'
<Operacion>
    <FechaOperacion Fecha="2026-04-30">
        <NuevosEmpleados>
            <NuevoEmpleado IdPuesto="1" IdDepartamento="1" IdTipoDocumento="1" Usuario="Willy" ValorTipoDocumento="110011001" Nombre="Carlos Mendoza" CuentaBancaria="CR2415115201001026284066"/>
            <NuevoEmpleado IdPuesto="2" IdDepartamento="1" IdTipoDocumento="1" Usuario="Willy" ValorTipoDocumento="305827920" Nombre="Ana Rodriguez" CuentaBancaria="CR2415115201901026284067"/>
            <NuevoEmpleado IdPuesto="3" IdDepartamento="1" IdTipoDocumento="1" Usuario="Willy" ValorTipoDocumento="194739285" Nombre="Nicolas Vargas" CuentaBancaria="CR2415115201901026392748"/>
        </NuevosEmpleados>
        
        <AsociacionEmpleadoDeducciones>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="110011001" IdTipoDeduccion="1" Monto="0.00"/>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="305827920" IdTipoDeduccion="2" Monto="50000.00"/>
        </AsociacionEmpleadoDeducciones>

        <AsignarJornada ValorDocumentoIdentidad="110011001" Jornada="Diurno" InicioSemana="2026-05-01"/>
        <AsignarJornada ValorDocumentoIdentidad="305827920" Jornada="Vespertino" InicioSemana="2026-05-01"/>
        <AsignarJornada ValorDocumentoIdentidad="194739285" Jornada="Nocturno" InicioSemana="2026-05-01"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-01">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-01T06:00:00" HoraSalida="2026-05-01T16:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-01T14:00:00" HoraSalida="2026-05-02T01:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-01T22:00:00" HoraSalida="2026-05-02T08:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-02">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-02T06:00:00" HoraSalida="2026-05-02T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-02T14:00:00" HoraSalida="2026-05-02T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-02T22:00:00" HoraSalida="2026-05-03T06:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-03">
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-03T14:00:00" HoraSalida="2026-05-03T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-03T22:00:00" HoraSalida="2026-05-04T06:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-04">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-04T06:00:00" HoraSalida="2026-05-04T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-04T14:00:00" HoraSalida="2026-05-04T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-04T22:00:00" HoraSalida="2026-05-05T08:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-05">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-05T06:00:00" HoraSalida="2026-05-05T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-05T14:00:00" HoraSalida="2026-05-05T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-05T22:00:00" HoraSalida="2026-05-06T06:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-06">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-06T06:00:00" HoraSalida="2026-05-06T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-06T14:00:00" HoraSalida="2026-05-07T00:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-06T22:00:00" HoraSalida="2026-05-07T06:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-07">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-07T06:00:00" HoraSalida="2026-05-07T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-07T14:00:00" HoraSalida="2026-05-07T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-07T22:00:00" HoraSalida="2026-05-08T06:00:00"/>
        <AsignarJornada ValorDocumentoIdentidad="110011001" Jornada="Vespertino" InicioSemana="2026-05-08"/>
        <AsignarJornada ValorDocumentoIdentidad="305827920" Jornada="Nocturno" InicioSemana="2026-05-08"/>
        <AsignarJornada ValorDocumentoIdentidad="194739285" Jornada="Diurno" InicioSemana="2026-05-08"/>
        <AsociacionEmpleadoDeducciones>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="305827920" IdTipoDeduccion="3" Monto="25000.00"/>
        </AsociacionEmpleadoDeducciones>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-08">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-08T14:00:00" HoraSalida="2026-05-08T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-08T22:00:00" HoraSalida="2026-05-09T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-08T06:00:00" HoraSalida="2026-05-08T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-09">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-09T14:00:00" HoraSalida="2026-05-09T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-09T22:00:00" HoraSalida="2026-05-10T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-09T06:00:00" HoraSalida="2026-05-09T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-10">
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-10T22:00:00" HoraSalida="2026-05-11T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-10T06:00:00" HoraSalida="2026-05-10T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-11">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-11T14:00:00" HoraSalida="2026-05-11T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-11T06:00:00" HoraSalida="2026-05-11T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-12">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-12T14:00:00" HoraSalida="2026-05-12T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-12T22:00:00" HoraSalida="2026-05-13T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-12T06:00:00" HoraSalida="2026-05-12T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-13">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-13T14:00:00" HoraSalida="2026-05-13T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-13T22:00:00" HoraSalida="2026-05-14T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-13T06:00:00" HoraSalida="2026-05-13T14:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-14">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-14T14:00:00" HoraSalida="2026-05-14T22:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-14T22:00:00" HoraSalida="2026-05-15T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-14T06:00:00" HoraSalida="2026-05-14T14:00:00"/>
        <AsignarJornada ValorDocumentoIdentidad="110011001" Jornada="Nocturno" InicioSemana="2026-05-15"/>
        <AsignarJornada ValorDocumentoIdentidad="305827920" Jornada="Diurno" InicioSemana="2026-05-15"/>
        <AsignarJornada ValorDocumentoIdentidad="194739285" Jornada="Vespertino" InicioSemana="2026-05-15"/>
        
        <AsociacionEmpleadoDeducciones>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="110011001" IdTipoDeduccion="3" Monto="15000.00"/>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="194739285" IdTipoDeduccion="1" Monto="0.00"/>
        </AsociacionEmpleadoDeducciones>
        
        <DesasociacionEmpleadoDeducciones>
            <DesasociacionEmpleadoConDeduccion ValorTipoDocumento="194739285" IdTipoDeduccion="2"/>
        </DesasociacionEmpleadoDeducciones>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-15">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-15T22:00:00" HoraSalida="2026-05-16T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-15T06:00:00" HoraSalida="2026-05-15T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-15T14:00:00" HoraSalida="2026-05-15T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-16">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-16T22:00:00" HoraSalida="2026-05-17T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-16T06:00:00" HoraSalida="2026-05-16T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-16T14:00:00" HoraSalida="2026-05-16T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-17">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-17T22:00:00" HoraSalida="2026-05-18T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-17T06:00:00" HoraSalida="2026-05-17T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-17T14:00:00" HoraSalida="2026-05-17T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-18">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-18T22:00:00" HoraSalida="2026-05-19T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-18T06:00:00" HoraSalida="2026-05-18T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-18T14:00:00" HoraSalida="2026-05-18T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-19">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-19T22:00:00" HoraSalida="2026-05-20T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-19T06:00:00" HoraSalida="2026-05-19T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-19T14:00:00" HoraSalida="2026-05-19T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-20">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-20T22:00:00" HoraSalida="2026-05-21T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-20T06:00:00" HoraSalida="2026-05-20T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-20T14:00:00" HoraSalida="2026-05-20T22:00:00"/>
    </FechaOperacion>

    <FechaOperacion Fecha="2026-05-21">
        <MarcaAsistencia ValorDocumentoIdentidad="110011001" HoraEntrada="2026-05-21T22:00:00" HoraSalida="2026-05-22T06:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="305827920" HoraEntrada="2026-05-21T06:00:00" HoraSalida="2026-05-21T14:00:00"/>
        <MarcaAsistencia ValorDocumentoIdentidad="194739285" HoraEntrada="2026-05-21T14:00:00" HoraSalida="2026-05-21T22:00:00"/>
        <AsignarJornada ValorDocumentoIdentidad="110011001" Jornada="Diurno" InicioSemana="2026-05-22"/>
        <AsignarJornada ValorDocumentoIdentidad="305827920" Jornada="Vespertino" InicioSemana="2026-05-22"/>
        <AsignarJornada ValorDocumentoIdentidad="194739285" Jornada="Nocturno" InicioSemana="2026-05-22"/>
        
        <AsociacionEmpleadoDeducciones>
            <AsociacionEmpleadoConDeduccion ValorTipoDocumento="305827920" IdTipoDeduccion="2" Monto="30000.00"/>
        </AsociacionEmpleadoDeducciones>
        
        <DesasociacionEmpleadoDeducciones>
            <DesasociacionEmpleadoConDeduccion ValorTipoDocumento="110011001" IdTipoDeduccion="1"/>
        </DesasociacionEmpleadoDeducciones>
    </FechaOperacion>
</Operacion>
'

EXEC dbo.spETLCargaOperacionEmpleado
    @ParametroXML = @MiXML,
    @outResultCode = @ResultadoCodigo OUTPUT;

-- 4. Ver si la operación fue exitosa (Debería retornar 0)
SELECT @ResultadoCodigo AS [CodigoResultadoETL];
