import { Injectable } from '@angular/core';
import { HttpClient, HttpParams, HttpHeaders } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { ClienteModel } from './models/cliente.model';

@Injectable({
  providedIn: 'root'
})
export class ClienteEnderecoService {

  // URL base do webservice TOTVS
  private readonly API_URL = '/rest/clientes'; // Ajuste conforme ambiente
  private readonly VIACEP_URL = 'https://viacep.com.br/ws';

  private httpOptions = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    })
  };

  constructor(private http: HttpClient) { }

  /**
   * Buscar lista de clientes com filtros
   */
  buscarClientes(codigo?: string, nome?: string): Observable<any> {
    let params = new HttpParams();
    
    if (codigo) {
      params = params.set('codigo', codigo);
    }
    
    if (nome) {
      params = params.set('nome', nome);
    }

    // Como não temos endpoint GET, vamos simular ou usar um endpoint de consulta
    // Para este exemplo, vou criar uma estrutura que seria retornada
    return this.http.get<any>(`${this.API_URL}`, { params, ...this.httpOptions })
      .pipe(
        map(response => {
          // Se o webservice não retornar no formato esperado, adaptar aqui
          return {
            data: response.clientes || response.data || [],
            total: response.total || 0,
            erro: response.erro || false,
            mensagem: response.mensagem || 'Consulta realizada com sucesso'
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Buscar endereço via ViaCEP
   */
  buscarCEP(cep: string): Observable<any> {
    const cepLimpo = cep.replace(/\D/g, '');
    
    if (cepLimpo.length !== 8) {
      return throwError(() => new Error('CEP deve ter 8 dígitos'));
    }

    return this.http.get<any>(`${this.VIACEP_URL}/${cepLimpo}/json/`)
      .pipe(
        map(response => {
          if (response.erro) {
            throw new Error('CEP não encontrado');
          }
          return {
            ...response,
            erro: false,
            mensagem: 'CEP encontrado com sucesso'
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Atualizar endereço completo do cliente
   */
  atualizarEndereco(dados: any): Observable<any> {
    const url = `${this.API_URL}/${dados.codigo}/${dados.loja}`;
    
    const payload = {
      endereco: dados.endereco,
      bairro: dados.bairro,
      cidade: dados.cidade,
      estado: dados.estado,
      cep: dados.cep,
      complemento: dados.complemento,
      numero: dados.numero
    };

    return this.http.put<any>(url, payload, this.httpOptions)
      .pipe(
        map(response => {
          return {
            erro: response.erro || false,
            mensagem: response.mensagem || 'Endereço atualizado com sucesso',
            codigo: response.codigo,
            loja: response.loja,
            dados: response
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Atualizar endereço apenas pelo CEP (endpoint PATCH)
   */
  atualizarEnderecoCEP(codigo: string, loja: string, cep: string): Observable<any> {
    const url = `${this.API_URL}/${codigo}/${loja}/cep/${cep}`;
    
    return this.http.patch<any>(url, {}, this.httpOptions)
      .pipe(
        map(response => {
          return {
            erro: response.erro || false,
            mensagem: response.mensagem || 'Endereço atualizado via CEP com sucesso',
            endereco_atualizado: response.endereco_atualizado || true,
            dados_cep: response.dados_cep || {},
            codigo: response.codigo,
            loja: response.loja
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Incluir novo cliente (se necessário)
   */
  incluirCliente(cliente: ClienteModel): Observable<any> {
    return this.http.post<any>(this.API_URL, cliente, this.httpOptions)
      .pipe(
        map(response => {
          return {
            erro: response.erro || false,
            mensagem: response.mensagem || 'Cliente incluído com sucesso',
            codigo: response.codigo,
            loja: response.loja,
            dados: response
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Excluir cliente (se necessário)
   */
  excluirCliente(codigo: string, loja: string): Observable<any> {
    const url = `${this.API_URL}/${codigo}/${loja}`;
    
    return this.http.delete<any>(url, this.httpOptions)
      .pipe(
        map(response => {
          return {
            erro: response.erro || false,
            mensagem: response.mensagem || 'Cliente excluído com sucesso',
            codigo: response.codigo,
            loja: response.loja
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Buscar cliente específico por código e loja
   */
  buscarCliente(codigo: string, loja: string): Observable<any> {
    const url = `${this.API_URL}/${codigo}/${loja}`;
    
    return this.http.get<any>(url, this.httpOptions)
      .pipe(
        map(response => {
          return {
            erro: response.erro || false,
            mensagem: response.mensagem || 'Cliente encontrado',
            cliente: response.cliente || response,
            dados: response
          };
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Validar CEP
   */
  validarCEP(cep: string): boolean {
    const cepLimpo = cep.replace(/\D/g, '');
    return cepLimpo.length === 8 && /^\d{8}$/.test(cepLimpo);
  }

  /**
   * Formatar CEP
   */
  formatarCEP(cep: string): string {
    const cepLimpo = cep.replace(/\D/g, '');
    if (cepLimpo.length === 8) {
      return cepLimpo.replace(/(\d{5})(\d{3})/, '$1-$2');
    }
    return cep;
  }

  /**
   * Limpar máscara de CEP
   */
  limparCEP(cep: string): string {
    return cep.replace(/\D/g, '');
  }

  /**
   * Validar dados de endereço
   */
  validarEndereco(endereco: any): { valido: boolean; erros: string[] } {
    const erros: string[] = [];

    if (!endereco.cep || !this.validarCEP(endereco.cep)) {
      erros.push('CEP é obrigatório e deve ter 8 dígitos');
    }

    if (!endereco.logradouro || endereco.logradouro.trim().length < 3) {
      erros.push('Logradouro é obrigatório e deve ter pelo menos 3 caracteres');
    }

    if (!endereco.bairro || endereco.bairro.trim().length < 2) {
      erros.push('Bairro é obrigatório e deve ter pelo menos 2 caracteres');
    }

    if (!endereco.localidade || endereco.localidade.trim().length < 2) {
      erros.push('Cidade é obrigatória e deve ter pelo menos 2 caracteres');
    }

    if (!endereco.uf || endereco.uf.length !== 2) {
      erros.push('Estado é obrigatório e deve ter 2 caracteres');
    }

    return {
      valido: erros.length === 0,
      erros
    };
  }

  /**
   * Tratamento de erros
   */
  private handleError = (error: any): Observable<never> => {
    console.error('Erro no serviço:', error);

    let mensagemErro = 'Erro interno do servidor';
    
    if (error.error) {
      if (typeof error.error === 'string') {
        mensagemErro = error.error;
      } else if (error.error.mensagem) {
        mensagemErro = error.error.mensagem;
      } else if (error.error.message) {
        mensagemErro = error.error.message;
      }
    } else if (error.message) {
      mensagemErro = error.message;
    }

    // Status HTTP específicos
    switch (error.status) {
      case 400:
        mensagemErro = 'Dados inválidos: ' + mensagemErro;
        break;
      case 404:
        mensagemErro = 'Recurso não encontrado: ' + mensagemErro;
        break;
      case 500:
        mensagemErro = 'Erro interno do servidor: ' + mensagemErro;
        break;
      case 0:
        mensagemErro = 'Erro de conexão com o servidor';
        break;
    }

    return throwError(() => ({
      status: error.status || 0,
      error: {
        mensagem: mensagemErro,
        detalhes: error
      }
    }));
  };
}
