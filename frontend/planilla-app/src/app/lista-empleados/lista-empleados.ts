import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { SlicePipe } from '@angular/common';
import { Router } from '@angular/router';
import { EmpleadoService } from '../services/lista-empleado';
import { Auth } from '../services/auth';
import { Empleado, Puesto } from '../models/empleado.interface';

@Component({
  selector: 'app-empleados-lista',
  imports: [FormsModule],
  templateUrl: './lista-empleados.html',
})
export class EmpleadosLista implements OnInit {
  empleados: Empleado[] = [];
  puestos: Puesto[] = [];
  filtro = '';
  tipoFiltro = 0;
  error = '';
  cargando = false;

  empleadoSeleccionado: Empleado | null = null;
  modoModal: 'ver' | 'insertar' | 'editar' | 'eliminar' | null = null;

  form: Partial<Empleado> = {};
  erroresValidacion: { [key: string]: string } = {};

  constructor(
    private empleadoService: EmpleadoService,
    private authService: Auth,
    private router: Router,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    if (!this.authService.estaLogueado) {
      this.router.navigate(['/login']);
      return;
    }
    this.cargarPuestos();
    this.cargarEmpleados();
  }

  cargarEmpleados(): void {
    this.cargando = true;
    this.error = '';
    this.empleadoService.listar(this.filtro).subscribe({
      next: (data) => {
        this.empleados = data;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = err.error?.mensaje ?? 'Error al cargar empleados';
        this.cargando = false;
        this.cdr.detectChanges();
      },
    });
  }

  cargarPuestos(): void {
    this.empleadoService.puestos().subscribe({
      next: (data) => {
        this.puestos = data;
        this.cdr.detectChanges();
      },
      error: () => {},
    });
  }

  //   navegarMovimientos(empleado: Empleado) {
  //     this.router.navigate([`movimientos/${empleado.id}`], {
  //       queryParams: {
  //         documentoIdentidad: empleado.valorDocumentoIdentidad,
  //         nombreEmpleado: empleado.nombre,
  //         saldo: empleado.saldoVacaciones,
  //       },
  //     });
  //   }

  abrirInsertar(): void {
    this.form = { Activo: true };
    this.modoModal = 'insertar';
  }

  abrirEditar(e: Empleado): void {
    this.form = { ...e };
    this.modoModal = 'editar';
  }

  abrirVer(e: Empleado): void {
    this.empleadoSeleccionado = e;
    this.modoModal = 'ver';
  }

  abrirEliminar(e: Empleado): void {
    this.empleadoSeleccionado = e;
    this.modoModal = 'eliminar';
  }

  cerrarModal(): void {
    this.modoModal = null;
    this.empleadoSeleccionado = null;
    this.form = {};
    this.error = '';
    this.erroresValidacion = {};
  }

  validarFormulario(): boolean {
    this.erroresValidacion = {};

    if (
      !this.form.valorDocumentoIdentidad ||
      this.form.valorDocumentoIdentidad.toString().trim() === ''
    ) {
      this.erroresValidacion['cedula'] = 'La cédula es requerida';
    }

    if (!this.form.nombre || this.form.nombre.trim() === '') {
      this.erroresValidacion['nombre'] = 'El nombre es requerido';
    }

    if (!this.form.idPuesto) {
      this.erroresValidacion['puesto'] = 'El puesto es requerido';
    }

    return Object.keys(this.erroresValidacion).length === 0;
  }

  esFormularioValido(): boolean {
    return !!(
      this.form.valorDocumentoIdentidad &&
      this.form.valorDocumentoIdentidad.toString().trim() !== '' &&
      this.form.nombre &&
      this.form.nombre.trim() !== '' &&
      this.form.idPuesto
    );
  }

  guardar(): void {
    if (!this.validarFormulario()) {
      this.cdr.detectChanges();
      return;
    }

    this.error = '';
    const empleado = this.form as Empleado;

    const op =
      this.modoModal === 'insertar'
        ? this.empleadoService.insertar(empleado)
        : this.empleadoService.actualizar(empleado);

    op.subscribe({
      next: () => {
        this.cerrarModal();
        this.cargarEmpleados();
      },
      error: (err) => {
        this.error = err.error?.mensaje ?? 'Error al guardar';
        this.cdr.detectChanges();
      },
    });
  }

  confirmarEliminar(): void {
    if (!this.empleadoSeleccionado) return;
    this.empleadoService.eliminar(this.empleadoSeleccionado.id).subscribe({
      next: () => {
        this.cerrarModal();
        this.cargarEmpleados();
      },
      error: (err) => {
        this.error = err.error?.mensaje ?? 'Error al eliminar';
        this.cdr.detectChanges();
      },
    });
  }

  logout(): void {
    this.authService.logout(this.authService.userId).subscribe({
      next: () => {
        this.authService.cerrarSesion();
        this.router.navigate(['/login']);
      },
      error: () => {
        this.authService.cerrarSesion();
        this.router.navigate(['/login']);
      },
    });
  }
}
