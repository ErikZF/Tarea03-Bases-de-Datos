import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class PlanillaService {
  private apiUrl = 'http://localhost:5223/api/planilla';

  constructor(private http: HttpClient) {}

  consultarHistorialSemanal(empleadoId: number, limite?: number): Observable<any[]> {
    const url = limite
      ? `${this.apiUrl}/semanal/${empleadoId}?limite=${limite}`
      : `${this.apiUrl}/semanal/${empleadoId}`;
    return this.http.get<any[]>(url);
  }

  consultarDeduccionesSemanales(planillaSemanalId: number, empleadoId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/semanal/${planillaSemanalId}/deducciones?empleadoId=${empleadoId}`,
    );
  }

  consultarAsistenciaDiaria(planillaSemanalId: number, empleadoId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/semanal/${planillaSemanalId}/asistencia?empleadoId=${empleadoId}`,
    );
  }

  consultarHistorialMensual(empleadoId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/mensual/${empleadoId}`);
  }

  consultarDeduccionesMensuales(planillaMensualId: number, empleadoId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.apiUrl}/mensual/${planillaMensualId}/deducciones?empleadoId=${empleadoId}`,
    );
  }
}
