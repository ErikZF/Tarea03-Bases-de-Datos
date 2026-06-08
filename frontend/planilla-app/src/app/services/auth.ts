import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
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
    sessionStorage.setItem('username', res.username);
  }

  cerrarSesion(): void {
    sessionStorage.clear();
  }

  get userId(): number {
    return parseInt(sessionStorage.getItem('userId') ?? '0');
  }

  get username(): string {
    return sessionStorage.getItem('username') ?? '';
  }

  get estaLogueado(): boolean {
    return !!sessionStorage.getItem('userId');
  }
}
