CREATE OR ALTER PROCEDURE dbo.spCargarCatalogosXML
    @outResultCode INT OUTPUT
AS
BEGIN
BEGIN TRY

    SET NOCOUNT ON
    SET @outResultCode = 0

        DECLARE @xmlData XML = 
        '
        <Catalogo>
        <TiposDeJornada>
            <TipoDeJornada id="1" Nombre="Diurno" HoraInicio="6:00" HoraFin="14:00"/>
            <TipoDeJornada id="2" Nombre="Vespertino" HoraInicio="14:00" HoraFin="22:00"/>
            <TipoDeJornada id="3" Nombre="Nocturno" HoraInicio="22:00" HoraFin="06:00"/>
        </TiposDeJornada>
        <Puestos>
            <Puesto Nombre="Electricista" SalarioXHora="1200"/>
            <Puesto Nombre="Auxiliar de Laboratorio" SalarioXHora="1250"/>
            <Puesto Nombre="Operador de Maquina" SalarioXHora="1025"/>
        </Puestos>
        <Feriados>
            <Feriado Id="1" Nombre="Dia de Juan Santamaria" Fecha="20220411"/>
            <Feriado Id="2" Nombre="Jueves Santo" Fecha="20220414"/>
            <Feriado Id="3" Nombre="Viernes Santo" Fecha="20220415"/>
            <Feriado Id="4" Nombre="Dia del trabajo" Fecha="20220501"/>
        </Feriados>
        <TiposDeMovimiento>
            <TipoDeMovimiento Id="1" Nombre="Credito Horas ordinarias" Accion="+" />
            <TipoDeMovimiento Id="2" Nombre="Credito Horas Extra Normales" Accion="+"/>
            <TipoDeMovimiento Id="3" Nombre="Credito Horas Extra Dobles" Accion="+"/>
            <TipoDeMovimiento Id="4" Nombre="Deducciones de ley" Accion="-" />
            <TipoDeMovimiento Id="5" Nombre="Deducciones Asociacion Solidarista" Accion="-" />
            <TipoDeMovimiento Id="6" Nombre="Deduccion Ahorro Vacacional" Accion="-" />
            <TipoDeMovimiento Id="7" Nombre="Pension Alimenticia" Accion="-" />
            <TipoDeMovimiento Id="8" Nombre="Embargo judicial" Accion="-" />
        </TiposDeMovimiento>
        <TiposDeDeduccion>
            <TipoDeDeduccion Id="1" Obligatorio="1" Porcentual="1" Valor="0.1067" IdTipoMov="4"/>
            <TipoDeDeduccion Id="2" Obligatorio="0" Porcentual="1" Valor="0.05" IdTipoMov="5" />
            <TipoDeDeduccion Id="3" Obligatorio="0" Porcentual="0" Valor="0" IdTipoMov="6"/>
            <TipoDeDeduccion Id="4" Obligatorio="0" Porcentual="0" Valor="0" IdTipoMov="7"/>
            <TipoDeDeduccion Id="5" Obligatorio="0" Porcentual="0" Valor="0" IdTipoMov="8"/>
        </TiposDeDeduccion>
        <Usuarios>
            <Usuario pwd="1234" username="Goku" tipo="administrador"/>
            <Usuario pwd="1234" username="Willy" tipo="empleado"/>
        </Usuarios>
        <TiposDeEvento>
            <TipoEvento Id="1" Nombre="login"/>
            <TipoEvento Id="2" Nombre="logout"/>
            <TipoEvento Id="3" Nombre="Listar empleados"/>
            <TipoEvento Id="4" Nombre="Listar empleados con filtro"/>
            <TipoEvento Id="5" Nombre="Insertar empleado"/>
        </TiposDeEvento>
        <Departamentos>
            <Departamento Id="1" Nombre="Operaciones"/>
            <Departamento Id="2" Nombre="Administración"/>
            <Departamento Id="3" Nombre="Recursos Humanos"/>
        </Departamentos>
        <TiposDeDocumento>
            <TipoDeDocumento Id="1" Nombre="Cédula de Identidad"/>
            <TipoDeDocumento Id="2" Nombre="Pasaporte"/>
            <TipoDeDocumento Id="3" Nombre="DIMEX / Cédula de Residencia"/>
        </TiposDeDocumento>
        </Catalogo>
        '
        
        BEGIN TRANSACTION

            --Cargar tipos de Jornada
            INSERT dbo.TipoJornada
            (
                id
                ,Nombre
                ,HoraInicio
                ,HoraFin
            )
            SELECT
                T.Item.value('@id', 'INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
                ,T.Item.value('@HoraInicio', 'TIME(0)')
                ,T.Item.value('@HoraFin', 'TIME(0)')
            FROM
                @xmlData.nodes('/Catalogo/TiposDeJornada/TipoDeJornada')
                AS T(Item)


            --Cargar Puestos
            INSERT dbo.Puesto
            (
                Nombre
                ,SalarioXHora
            )
            SELECT
                T.Item.value('@Nombre', 'VARCHAR(256)')
                ,T.Item.value('@SalarioXHora', 'INT')
            FROM
                @xmlData.nodes('/Catalogo/Puestos/Puesto')
                AS T(Item)
        


            --Insertar Feriados
            INSERT dbo.Feriado 
            (
                id
                ,Nombre
                ,Fecha
            )           
            SELECT
                T.Item.value('@Id','INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
                ,T.Item.value('@Fecha', 'DATE')                
            FROM 
                @xmlData.nodes('/Catalogo/Feriados/Feriado') 
                AS T(Item)



            --Insertar tipos de movimiento
            INSERT dbo.TipoMovimiento
            (
                id
                ,Nombre
                ,Accion
            )
            SELECT
                T.Item.value('@Id', 'INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
                ,T.Item.value('@Accion', 'VARCHAR(8)')
            FROM
                @xmlData.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento')
                AS T(Item)

        
            --Insertar tipos de deduccion
            INSERT dbo.TipoDeduccion
            (
                id
                ,Nombre
                ,EsObligatoria
                ,EsPorcentual
                ,Valor
                ,idTipoMovimiento
            )
            SELECT
                T.Item.value('@Id', 'INT')
                ,TM.Nombre
                ,T.Item.value('@Obligatorio', 'BIT')
                ,T.Item.value('@Porcentual', 'BIT')
                ,T.Item.value('@Valor', 'REAL')
                ,T.Item.value('@IdTipoMov', 'INT')
                
            FROM
                @xmlData.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion')
                AS T(Item)
            INNER JOIN dbo.TipoMovimiento AS TM 
                ON TM.id = T.Item.value('@IdTipoMov', 'INT')
                

            --Insertar Usuarios
            INSERT dbo.Usuario
            (
                Username
                ,PasswordHash
                ,Tipo
            )
            SELECT
                T.Item.value('@username', 'VARCHAR(256)')
                ,T.Item.value('@pwd', 'VARCHAR(256)')
                ,T.Item.value('@tipo', 'VARCHAR(256)')
            FROM
                @xmlData.nodes('/Catalogo/Usuarios/Usuario')
                AS T(Item)

            --Insertar Tipo de Evento
            INSERT dbo.TipoEvento
            (
                id
                ,Nombre
            )
            SELECT
                T.Item.value('@Id', 'INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
            FROM
                @xmlData.nodes('/Catalogo/TiposDeEvento/TipoEvento')
                AS T(Item)

            --Insertar Departamentos
            INSERT dbo.Departamento
            (
                id
                ,Nombre
            )
            SELECT
                T.Item.value('@Id', 'INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
            FROM
                @xmlData.nodes('/Catalogo/Departamentos/Departamento')
                AS T(Item)

                --Insertar Tipos de Documento de Identidad
            INSERT dbo.TipoDocIdentidad
            (
                id
                ,Nombre
            )
            SELECT
                T.Item.value('@Id', 'INT')
                ,T.Item.value('@Nombre', 'VARCHAR(256)')
            FROM
                @xmlData.nodes('/Catalogo/TiposDeDocumento/TipoDeDocumento')
                AS T(Item)

        COMMIT TRANSACTION


END TRY
BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResultCode = 50008;

        DECLARE @ErrorNum INT = ERROR_NUMBER();
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSev INT = ERROR_SEVERITY();
        DECLARE @ErrorStat INT = ERROR_STATE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorProc NVARCHAR(128) = ERROR_PROCEDURE();

        EXEC dbo.spInsertarError
             @InErrorNumber    = @ErrorNum
            ,@InErrorMessage   = @ErrorMsg
            ,@InErrorSeverity  = @ErrorSev
            ,@InErrorState     = @ErrorStat
            ,@InErrorLine      = @ErrorLine
            ,@InErrorProcedure = @ErrorProc
            ,@outResultCode    = @outResultCode OUTPUT;
END CATCH
END
GO

DECLARE @outResultCode INT
EXEC dbo.spCargarCatalogosXML @outResultCode OUTPUT