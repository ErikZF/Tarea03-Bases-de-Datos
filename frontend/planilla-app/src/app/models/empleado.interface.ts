export interface Empleado {
  id: number;
  valorDocumentoIdentidad: string;
  nombre: string;
  idPuesto: number;
  nombrePuesto: string;
  fechaContratacion: Date;
  cuentaBancaria: string;
  Activo: boolean;
}

export interface Puesto {
  id: number;
  nombre: string;
}
