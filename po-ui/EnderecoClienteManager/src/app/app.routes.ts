import { Routes } from '@angular/router';
import { ClienteEnderecoComponent } from './components/cliente-endereco/cliente-endereco.component';
import { LoginComponent } from './components/login/login.component';
import { AuthGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { 
    path: 'clientes', 
    component: ClienteEnderecoComponent,
    canActivate: [AuthGuard]
  },
  { path: '**', redirectTo: '/login' }
];
