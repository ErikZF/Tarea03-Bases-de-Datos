import { Routes } from '@angular/router';
import { Login } from './login/login';
import { authGuard } from './guards/auth-guard';
import { EmpleadosLista } from './lista-empleados/lista-empleados';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: Login },
  { path: 'lista-empleados', component: EmpleadosLista },
];
