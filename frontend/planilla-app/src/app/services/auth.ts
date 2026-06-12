import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { LoginRequest, LoginResponse } from '../models/auth.interface';

const API = 'http://localhost:5223/api/auth';

@Injectable({ providedIn: 'root' })
export class Auth {
  constructor(private http: HttpClient) {}

  login(data: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${API}/login`, data);
  }

  logout(userId: number): Observable<void> {
    return this.http.post<void>(`${API}/logout`, null, {
      headers: { 'X-User-Id': userId.toString() },
    });
  }

  guardarSesion(res: LoginResponse): void {
    sessionStorage.setItem('userId', res.userId.toString());
    sessionStorage.setItem('userIdActivo', res.userId.toString());
    sessionStorage.setItem('username', res.username);
    sessionStorage.setItem('esAdmin', res.tipo ? '1' : '0');
  }

  cerrarSesion(): void {
    sessionStorage.clear();
  }

  get userId(): number {
    return parseInt(sessionStorage.getItem('userIdActivo') ?? '0');
  }

  get userIdReal(): number {
    return parseInt(sessionStorage.getItem('userId') ?? '0');
  }

  get username(): string {
    return sessionStorage.getItem('username') ?? '';
  }

  get estaLogueado(): boolean {
    return !!sessionStorage.getItem('userId');
  }

  get esAdmin(): boolean {
    return sessionStorage.getItem('esAdmin') === '1';
  }

  impersonar(empleadoUsuarioId: number): void {
    sessionStorage.setItem('userIdActivo', empleadoUsuarioId.toString());
  }

  detenerImpersonacion(): void {
    const idReal = sessionStorage.getItem('userId') ?? '0';
    sessionStorage.setItem('userIdActivo', idReal);
  }
}
