import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, BehaviorSubject, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from '../../environments/environment';

export interface AuthConfig {
  username: string;
  password: string;
  company?: string;
  branch?: string;
}

export interface AuthToken {
  token: string;
  expires: Date;
  type: 'basic' | 'bearer' | 'jwt';
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly AUTH_STORAGE_KEY = 'totvs_auth_token';
  private currentTokenSubject = new BehaviorSubject<AuthToken | null>(null);
  public currentToken$ = this.currentTokenSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadStoredToken();
  }

  /**
   * Autentica usando Basic Auth
   */
  authenticateBasic(username?: string, password?: string): Observable<AuthToken> {
    console.log('Iniciando autenticação para:', username);
    
    let basicToken: string;
    
    if (username && password) {
      basicToken = btoa(`${username}:${password}`);
      console.log('Token Basic Auth gerado para:', username);
    } else if (environment.totvs.basicAuthToken) {
      basicToken = environment.totvs.basicAuthToken;
      console.log('Usando token do environment');
    } else {
      console.error('Credenciais não configuradas');
      return new Observable(observer => {
        observer.error(new Error('Credenciais não configuradas'));
      });
    }

    // Por enquanto, vamos apenas validar se as credenciais são admin/msadm
    if (username === 'admin' && password === 'msadm') {
      console.log('Credenciais válidas - admin/msadm');
      const authToken: AuthToken = {
        token: basicToken,
        expires: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 horas
        type: 'basic'
      };

      this.setToken(authToken);
      console.log('Token salvo com sucesso');
      return of(authToken);
    } else {
      console.log('Credenciais inválidas:', username);
      return new Observable(observer => {
        observer.error(new Error('Credenciais inválidas'));
      });
    }
  }

  /**
   * Autentica usando token JWT (se o TOTVS suportar)
   */
  authenticateJWT(credentials: AuthConfig): Observable<AuthToken> {
    const loginUrl = `${environment.api.baseUrl}/auth/login`;
    
    return this.http.post<any>(loginUrl, credentials).pipe(
      map(response => {
        const authToken: AuthToken = {
          token: response.access_token || response.token,
          expires: new Date(response.expires_in ? Date.now() + response.expires_in * 1000 : Date.now() + 24 * 60 * 60 * 1000),
          type: 'jwt'
        };
        
        this.setToken(authToken);
        return authToken;
      }),
      catchError(error => {
        console.error('Erro na autenticação JWT:', error);
        // Fallback para Basic Auth
        return this.authenticateBasic(credentials.username, credentials.password);
      })
    );
  }

  /**
   * Obtém o token atual
   */
  getCurrentToken(): AuthToken | null {
    return this.currentTokenSubject.value;
  }

  /**
   * Verifica se está autenticado
   */
  isAuthenticated(): boolean {
    const token = this.getCurrentToken();
    return token !== null && new Date() < token.expires;
  }

  /**
   * Obtém headers de autenticação
   */
  getAuthHeaders(): HttpHeaders {
    const token = this.getCurrentToken();
    
    if (!token) {
      // Tenta autenticação automática com credenciais do environment
      this.authenticateBasic().subscribe();
      return new HttpHeaders();
    }

    let headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });

    switch (token.type) {
      case 'basic':
        headers = headers.set('Authorization', `Basic ${token.token}`);
        break;
      case 'bearer':
      case 'jwt':
        headers = headers.set('Authorization', `Bearer ${token.token}`);
        break;
    }

    // Headers específicos do TOTVS se necessário
    if (environment.totvs.company) {
      headers = headers.set('Company', environment.totvs.company);
    }
    if (environment.totvs.branch) {
      headers = headers.set('Branch', environment.totvs.branch);
    }

    return headers;
  }

  /**
   * Faz logout
   */
  logout(): void {
    localStorage.removeItem(this.AUTH_STORAGE_KEY);
    this.currentTokenSubject.next(null);
  }

  /**
   * Salva token no storage
   */
  private setToken(token: AuthToken): void {
    localStorage.setItem(this.AUTH_STORAGE_KEY, JSON.stringify(token));
    this.currentTokenSubject.next(token);
  }

  /**
   * Carrega token salvo do storage
   */
  private loadStoredToken(): void {
    try {
      const stored = localStorage.getItem(this.AUTH_STORAGE_KEY);
      if (stored) {
        const token: AuthToken = JSON.parse(stored);
        token.expires = new Date(token.expires); // Reconstitui a data
        
        if (new Date() < token.expires) {
          this.currentTokenSubject.next(token);
        } else {
          localStorage.removeItem(this.AUTH_STORAGE_KEY);
        }
      }
    } catch (error) {
      console.error('Erro ao carregar token salvo:', error);
      localStorage.removeItem(this.AUTH_STORAGE_KEY);
    }
  }

  /**
   * Renovação automática de token
   */
  refreshTokenIfNeeded(): Observable<AuthToken | null> {
    const token = this.getCurrentToken();
    
    if (!token) {
      return this.authenticateBasic();
    }

    // Se o token expira em menos de 1 hora, renova
    const oneHour = 60 * 60 * 1000;
    if (token.expires.getTime() - Date.now() < oneHour) {
      return this.authenticateBasic();
    }

    return of(token);
  }
}
