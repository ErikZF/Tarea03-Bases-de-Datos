export interface Movimiento {
  id: number;
  idEmpleado: number;
  monto: number;
  nuevoSaldo: number;
  tipoMovimiento: string;
  postTime: Date;
  procesadoPor: string;
  postInIp: string;
}
