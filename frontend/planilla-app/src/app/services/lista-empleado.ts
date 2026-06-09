import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Empleado, Puesto } from '../models/empleado.interface';
import { Auth } from './auth';

const API = 'http://localhost:5223/api/empleados';

@Injectable({ providedIn: 'root' })
export class EmpleadoService {
  constructor(
    private http: HttpClient,
    private auth: Auth,
  ) {}

  listar(filtro: string): Observable<Empleado[]> {
    const params = new HttpParams()
      .set('filtro', filtro)
      .set('userId', this.auth.userId)
      .set('ip', '127.0.0.1');
    return this.http.get<Empleado[]>(API, { params });
  }

  consultar(id: number): Observable<Empleado> {
    return this.http.get<Empleado>(`${API}/${id}`);
  }

  puestos(): Observable<Puesto[]> {
    return this.http.get<Puesto[]>(`${API}/puestos`);
  }

  insertar(empleado: Empleado): Observable<void> {
    const params = new HttpParams().set('userId', this.auth.userId).set('ip', '127.0.0.1');
    return this.http.post<void>(API, empleado, { params });
  }

  actualizar(empleado: Empleado): Observable<void> {
    const params = new HttpParams().set('userId', this.auth.userId).set('ip', '127.0.0.1');
    return this.http.put<void>(`${API}/${empleado.id}`, empleado, { params });
  }

  eliminar(id: number): Observable<void> {
    const params = new HttpParams().set('userId', this.auth.userId).set('ip', '127.0.0.1');
    return this.http.delete<void>(`${API}/${id}`, { params });
  }
}
