import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DecimalPipe } from '@angular/common';
import { Auth } from '../services/auth';
import { ActivatedRoute, Router } from '@angular/router';
import { EmpleadoService } from '../services/lista-empleado';
import { PlanillaService } from '../services/planilla';

@Component({
  selector: 'app-menu-empleado',
  standalone: true,
  templateUrl: './menu-empleado.html',
  styleUrl: './menu-empleado.css',
  imports: [FormsModule, DecimalPipe],
})
export class MenuEmpleado implements OnInit {
  empleado: any = null;
  idEmpleadoActivo!: number;
  cargando = false;

  planillasSemanales: any[] = [];
  planillasMensuales: any[] = [];
  deduccionesDetalle: any[] = [];
  asistenciaDetalle: any[] = [];

  cantSemanas: number = 10;

  vistaActiva: 'semanal' | 'mensual' = 'semanal';
  modalTipo: 'deducciones' | 'asistencia' | null = null;
  registroSeleccionado: any = null;

  constructor(
    private authService: Auth,
    private route: ActivatedRoute,
    private router: Router,
    private empleadoService: EmpleadoService,
    private planillaService: PlanillaService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    const idEmpleado = this.route.snapshot.paramMap.get('id');

    if (idEmpleado) {
      this.idEmpleadoActivo = Number(idEmpleado);
      this.cargarPerfilEmpleado(this.idEmpleadoActivo);
    }
  }

  cargarPerfilEmpleado(id: number): void {
    this.cargando = true;

    this.empleadoService.consultar(id).subscribe({
      next: (data: any) => {
        this.empleado = data;
        this.cargando = false;
        this.cdr.detectChanges();

        this.cargarPlanillasSemanales(id);
        this.cargarPlanillasMensuales(id);
      },
      error: (err: any) => {
        this.cargando = false;
        this.cdr.detectChanges();
        console.error('Error al cargar datos del empleado', err);
      },
    });
  }

  cargarPlanillasSemanales(id: number): void {
    this.planillaService.consultarHistorialSemanal(id, this.cantSemanas).subscribe({
      next: (data: any[]) => {
        this.planillasSemanales = data;
        this.cdr.detectChanges();
      },
      error: (err: any) => console.error('Error cargando historial semanal', err),
    });
  }

  cargarPlanillasMensuales(id: number): void {
    this.planillaService.consultarHistorialMensual(id).subscribe({
      next: (data: any[]) => {
        this.planillasMensuales = data;
        this.cdr.detectChanges();
      },
      error: (err: any) => console.error('Error cargando historial mensual', err),
    });
  }

  aplicarFiltroSemanas(): void {
    this.cargarPlanillasSemanales(this.idEmpleadoActivo);
  }

  abrirDeduccionesSemana(planillaSemanal: any) {
    this.registroSeleccionado = planillaSemanal;
    this.modalTipo = 'deducciones';
    this.cargando = true;

    this.planillaService
      .consultarDeduccionesSemanales(planillaSemanal.id, this.idEmpleadoActivo)
      .subscribe({
        next: (data: any[]) => {
          this.deduccionesDetalle = data;
          this.cargando = false;
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.cargando = false;
          this.cdr.detectChanges();
          console.error('Error consultando rebajos semanales', err);
        },
      });
  }

  abrirDetalleAsistencia(planillaSemanal: any) {
    this.registroSeleccionado = planillaSemanal;
    this.modalTipo = 'asistencia';
    this.cargando = true;

    this.planillaService
      .consultarAsistenciaDiaria(planillaSemanal.id, this.idEmpleadoActivo)
      .subscribe({
        next: (data: any[]) => {
          this.asistenciaDetalle = data;
          this.cargando = false;
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.cargando = false;
          this.cdr.detectChanges();
          console.error('Error consultando asistencia de la semana', err);
        },
      });
  }

  abrirDeduccionesMes(planillaMensual: any) {
    this.registroSeleccionado = planillaMensual;
    this.modalTipo = 'deducciones';
    this.cargando = true;

    this.planillaService
      .consultarDeduccionesMensuales(planillaMensual.id, this.idEmpleadoActivo)
      .subscribe({
        next: (data: any[]) => {
          this.deduccionesDetalle = data;
          this.cargando = false;
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.cargando = false;
          this.cdr.detectChanges();
          console.error('Error consultando rebajos mensuales', err);
        },
      });
  }

  cerrarModal() {
    this.modalTipo = null;
    this.registroSeleccionado = null;
    this.deduccionesDetalle = [];
    this.asistenciaDetalle = [];
  }

  get esAdmin(): boolean {
    return this.authService.esAdmin;
  }

  volverAPanelAdmin(): void {
    this.authService.detenerImpersonacion();
    this.router.navigate(['lista-empleados']);
  }
}
