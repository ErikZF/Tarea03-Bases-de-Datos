import { Component, ChangeDetectorRef } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Auth } from '../services/auth';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
})
export class Login {
  username = '';
  password = '';
  error = '';
  cargando = false;

  constructor(
    private authService: Auth,
    private router: Router,
    private cdr: ChangeDetectorRef,
  ) {}

  onSubmit(): void {
    this.error = '';
    this.cargando = true;

    this.authService
      .login({
        username: this.username,
        password: this.password,
        postInIP: '127.0.0.1',
      })
      .subscribe({
        next: (res: any) => {
          this.authService.guardarSesion(res);
          this.router.navigate(['/empleados/lista']);
        },
        error: (err: any) => {
          this.error = err.error?.mensaje ?? 'Error al iniciar sesión';
          this.cargando = false;
          this.cdr.detectChanges();
        },
      });
  }
}
