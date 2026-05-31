
---

## Comandos de desarrollo

### Backend (.NET)

```bash
# Desde backend/PlanillaAPI/
dotnet run                     # Levanta API en http://localhost:5267
dotnet build                   # Compilar
dotnet watch run               # Hot reload
```

### Frontend (Angular)

```bash
# Desde frontend/planilla-app/
ng serve                       # Dev server en http://localhost:4200
ng build                       # Build de producción → dist/
ng generate component admin/nombre-componente --module app
ng generate component empleado/nombre-componente --module app
ng generate service shared/nombre-servicio
```

### Docker

```bash
# Desde la raíz del repo
docker compose up -d           # Levanta SQL Server 2022 + backend
docker compose down            # Bajar contenedores
docker compose logs -f         # Ver logs en tiempo real
```

### Base de datos (SSMS / sqlcmd)

```bash
# Crear la base y correr migraciones
sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i database/migrations/01_create_tables.sql
sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i database/migrations/02_create_procedures.sql

# Cargar catálogos y correr simulación
sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i database/etl/load_catalogos.sql
sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i database/etl/run_simulation.sql
```

## Convención de commits

```
feat(db): add spCierreSemanal
fix(backend): handle empty filter in spListarEmpleados
feat(frontend): add weekly payroll modal
docs: update task division
```

