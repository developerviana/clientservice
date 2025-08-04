import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { PoModule } from '@po-ui/ng-components';
import { PoNotificationService } from '@po-ui/ng-components';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, PoModule],
  template: `
    <div class="login-container">
      <div class="login-card">
        <div class="login-header">
          <p>Gerenciamento de Endereços de Clientes</p>
        </div>
        
        <form [formGroup]="loginForm" (ngSubmit)="onLogin()" (keydown.enter)="onLogin()" class="login-form">
          <po-input 
            p-label="Usuário" 
            formControlName="username"
            p-required="true"
            p-icon="po-icon-user"
            p-placeholder="Digite seu usuário">
          </po-input>
          
          <po-password 
            p-label="Senha" 
            formControlName="password"
            p-required="true"
            p-placeholder="Digite sua senha">
          </po-password>
          
          <po-button 
            p-label="Entrar" 
            [p-loading]="loading"
            [p-disabled]="loginForm.invalid"
            (p-click)="onLogin()"
            class="login-button">
          </po-button>
        </form>
      </div>
    </div>
  `,
  styles: [`
    .login-container {
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    
    .login-card {
      max-width: 450px;
      width: 100%;
      background: rgba(255, 255, 255, 0.95);
      backdrop-filter: blur(10px);
      border-radius: 25px;
      box-shadow: 0 25px 80px rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.2);
      overflow: hidden;
    }
    
    .login-header {
      background: linear-gradient(135deg, #3498db, #2980b9);
      color: white;
      padding: 30px;
      text-align: center;
    }
    
    .login-header h1 {
      margin: 0;
      font-size: 1.8rem;
      font-weight: 600;
    }
    
    .login-header p {
      margin: 5px 0 0 0;
      opacity: 0.9;
      font-size: 1rem;
    }
    
    .login-form {
      padding: 30px;
    }
    
    ::ng-deep .login-form .po-field {
      margin-bottom: 20px;
    }
    
    ::ng-deep .login-form .po-input {
      border-radius: 10px !important;
      border: 2px solid rgba(52, 152, 219, 0.2) !important;
      transition: all 0.3s ease;
    }
    
    ::ng-deep .login-form .po-input:focus {
      border-color: #3498db !important;
      box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1) !important;
    }
    
    ::ng-deep .login-button .po-button {
      width: 100%;
      background: linear-gradient(135deg, #27ae60, #16a085) !important;
      border: none !important;
      border-radius: 10px !important;
      padding: 12px 20px !important;
      font-weight: 600;
      transition: all 0.3s ease;
    }
    
    ::ng-deep .login-button .po-button:hover {
      background: linear-gradient(135deg, #16a085, #138d75) !important;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(39, 174, 96, 0.4);
    }
    
    @media (max-width: 480px) {
      .login-card {
        margin: 10px;
        border-radius: 20px;
      }
      
      .login-header {
        padding: 20px;
      }
      
      .login-form {
        padding: 20px;
      }
      
      .credentials-info {
        margin: 15px 20px 20px 20px;
        padding: 15px;
      }
    }
  `]
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  loading = false;
  returnUrl = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private notification: PoNotificationService
  ) {
    this.loginForm = this.fb.group({
      username: ['admin', Validators.required],
      password: ['msadm', Validators.required]
    });
  }

  ngOnInit(): void {
    // Pega a URL de retorno da query string
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/clientes';
    
    // Se já está logado, redireciona
    if (this.authService.isAuthenticated()) {
      this.router.navigate([this.returnUrl]);
    }
  }

  onLogin(): void {
    // Evita dupla execução se já estiver carregando
    if (this.loading) {
      return;
    }
    
    console.log('Tentativa de login iniciada');
    console.log('Form válido:', this.loginForm.valid);
    console.log('Valores do form:', this.loginForm.value);
    
    if (this.loginForm.valid) {
      this.loading = true;
      
      const { username, password } = this.loginForm.value;
      console.log('Credenciais:', { username, password: '***' });
      
      try {
        this.authService.authenticateBasic(username, password).subscribe({
          next: (result) => {
            console.log('Login bem-sucedido:', result);
            this.loading = false;
            this.notification.success('Login realizado com sucesso!');
            this.router.navigate([this.returnUrl]);
          },
          error: (error) => {
            console.error('Erro no login (subscribe):', error);
            this.loading = false;
            
            if (error.message === 'Credenciais inválidas') {
              this.notification.error('Usuário ou senha incorretos.');
            } else if (error.message === 'Servidor indisponível') {
              this.notification.error('Servidor TOTVS indisponível. Tente novamente.');
            } else {
              this.notification.error('Erro ao fazer login. Verifique suas credenciais.');
            }
          }
        });
      } catch (error) {
        console.error('Erro no login (try/catch):', error);
        this.loading = false;
        this.notification.error('Erro ao fazer login. Verifique suas credenciais.');
      }
    } else {
      console.log('Formulário inválido');
      this.notification.warning('Preencha todos os campos obrigatórios.');
    }
  }
}
