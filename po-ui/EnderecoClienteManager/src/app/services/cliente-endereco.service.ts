import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { map, catchError, switchMap } from 'rxjs/operators';
import { Cliente } from '../models/cliente.model';
import { AuthService } from './auth.service';
import { environment } from '../../environments/environment';

export interface ViaCepResponse {
  cep: string;
  logradouro: string;
  complemento: string;
  bairro: string;
  localidade: string;
  uf: string;
  ibge: string;
  gia: string;
  ddd: string;
  siafi: string;
}

export interface ApiResponse {
  sucesso: boolean;
  dados: any;
  mensagem: string;
  erro: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ClienteEnderecoService {

  private readonly baseUrl = environment.api.baseUrl;
  private readonly viaCepUrl = 'https://viacep.com.br/ws';

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) { }

  /**
   * Obtém headers autenticados
   */
  private getAuthenticatedHeaders(): Observable<HttpHeaders> {
    return this.authService.refreshTokenIfNeeded().pipe(
      map(() => this.authService.getAuthHeaders())
    );
  }

  /**
   * Lista todos os clientes
   */
  listarClientes(): Observable<ApiResponse> {
    console.log('🔗 Serviço: Iniciando listagem de clientes...');
    console.log('🌐 URL:', `${this.baseUrl}/WSCLIENTE/clientes`);
    
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers => {
        console.log('🔑 Headers autenticados obtidos');
        return this.http.get<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes`, { headers });
      }),
      map(response => {
        console.log('📨 Resposta completa do serviço:', response);
        return response;
      }),
      catchError(error => {
        console.error('❌ Erro no serviço:', error);
        return this.handleError(error);
      })
    );
  }

  /**
   * Busca um cliente específico
   */
  buscarCliente(codigo: string, loja: string): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.get<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}`, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Altera os dados de um cliente
   */
  alterarCliente(codigo: string, loja: string, dados: any): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.put<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}`, dados, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Atualiza endereço por CEP
   */
  atualizarEnderecoCep(codigo: string, loja: string, cep: string): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.put<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}/cep/${cep}`, {}, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Busca endereço pelo CEP via ViaCEP
   */
  buscarCep(cep: string): Observable<ViaCepResponse> {
    const cepLimpo = cep.replace(/\D/g, '');
    
    if (cepLimpo.length !== 8) {
      return throwError(() => new Error('CEP deve conter 8 dígitos'));
    }

    return this.http.get<ViaCepResponse>(`${this.viaCepUrl}/${cepLimpo}/json/`)
      .pipe(
        map(response => {
          if (response.hasOwnProperty('erro')) {
            throw new Error('CEP não encontrado');
          }
          return response;
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Inclui um novo cliente
   */
  incluirCliente(dados: any): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.post<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes`, dados, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Exclui um cliente
   */
  excluirCliente(codigo: string, loja: string): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.delete<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}`, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Importa clientes via CSV
   */
  importarClientesCSV(dados: any): Observable<ApiResponse> {
    return this.getAuthenticatedHeaders().pipe(
      switchMap(headers =>
        this.http.post<ApiResponse>(`${this.baseUrl}/WSCLIENTE/clientes/importar`, dados, { headers })
      ),
      catchError(this.handleError)
    );
  }

  /**
   * Tratamento de erros
   */
  private handleError = (error: any): Observable<never> => {
    let errorMessage = 'Erro desconhecido';
    
    if (error.error instanceof ErrorEvent) {
      // Erro do lado do cliente
      errorMessage = `Erro: ${error.error.message}`;
    } else {
      // Erro do lado do servidor
      errorMessage = `Código: ${error.status}, Mensagem: ${error.message}`;
      
      if (error.error && error.error.mensagem) {
        errorMessage = error.error.mensagem;
      }
    }
    
    console.error('Erro no serviço:', errorMessage);
    return throwError(() => new Error(errorMessage));
  };
}
