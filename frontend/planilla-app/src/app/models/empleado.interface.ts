export interface Empleado {
  id: number;
  valorDocumentoIdentidad: string;
  nombre: string;
  idPuesto: number;
  nombrePuesto: string;
  fechaContratacion: string;
  saldoVacaciones: number;
  Activo: boolean;
}

export interface Puesto {
  id: number;
  nombre: string;
}
