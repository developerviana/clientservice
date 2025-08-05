// Configuração específica para API TOTVS
// Coloque este código no component para testar a conexão

export class TesteApiConfig {
  
  // 1. Estrutura JSON para INCLUIR cliente
  static getJsonIncluirCliente(dados: any) {
    return {
      codigo: dados.codigo,
      loja: dados.loja, 
      nome: dados.nome,
      fantasia: dados.fantasia || '',
      cpf: dados.cpf,
      cep: dados.cep?.replace(/\D/g, '') || '',
      endereco: dados.endereco || '',
      bairro: dados.bairro || '',
      cidade: dados.cidade || '',
      estado: dados.estado || ''
    };
  }

  // 2. Estrutura JSON para EDITAR cliente via WS
  static getJsonEditarCliente(dados: any) {
    return {
      nome: dados.nome,
      nomeReduzido: dados.nomeReduzido,
      cep: dados.cep?.replace(/\D/g, '') || '',
      endereco: dados.endereco || '',
      cidade: dados.cidade || '',
      estado: dados.estado || '',
      pais: dados.pais || '105'
    };
  }

  // 3. Headers completos para TOTVS
  static getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic ' + btoa('admin:msadm'), // Altere para suas credenciais
      'Company': '99',
      'Branch': '01'
    };
  }

  // 4. URLs da API
  static getUrls(baseUrl: string = 'http://localhost:8181/rest') {
    return {
      listar: `${baseUrl}/WSCLIENTE/clientes`,
      incluir: `${baseUrl}/WSCLIENTE/clientes`,
      editar: (codigo: string, loja: string) => `${baseUrl}/rest/WSCLIENTE/${codigo}/${loja}`,
      excluir: (codigo: string, loja: string) => `${baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}`,
      buscar: (codigo: string, loja: string) => `${baseUrl}/WSCLIENTE/clientes/${codigo}/${loja}`
    };
  }

  // 5. Exemplo de como fazer requisição manual (para teste)
  static async testarConexao() {
    const headers = this.getHeaders();
    const urls = this.getUrls();
    
    try {
      const response = await fetch(urls.listar, {
        method: 'GET',
        headers: headers
      });
      
      const data = await response.json();
      console.log('✅ Conexão com API funcionando:', data);
      return data;
    } catch (error) {
      console.error('❌ Erro na conexão:', error);
      throw error;
    }
  }
}

// Como usar no component:
/*
export class ClienteEnderecoComponent {
  
  // Teste a conexão
  async testarApi() {
    try {
      const resultado = await TesteApiConfig.testarConexao();
      this.notification.success('API conectada com sucesso!');
    } catch (error) {
      this.notification.error('Erro na conexão: ' + error.message);
    }
  }

  // Exemplo de inclusão com JSON correto
  salvarNovoCliente(): void {
    if (this.formIncluir.valid) {
      const dadosForm = this.formIncluir.value;
      const jsonCorreto = TesteApiConfig.getJsonIncluirCliente(dadosForm);
      
      console.log('JSON que será enviado:', jsonCorreto);
      
      this.clienteService.incluirCliente(jsonCorreto).subscribe({
        next: (response) => {
          this.notification.success('Cliente incluído com sucesso!');
        },
        error: (error) => {
          console.error('Erro ao incluir:', error);
          this.notification.error('Erro: ' + error.message);
        }
      });
    }
  }

  // Exemplo de edição com JSON correto
  salvarClienteWS(): void {
    if (this.formAlterarWS.valid && this.clienteSelecionado) {
      const dadosForm = this.formAlterarWS.value;
      const jsonCorreto = TesteApiConfig.getJsonEditarCliente(dadosForm);
      
      console.log('JSON que será enviado para edição:', jsonCorreto);
      
      this.clienteService.alterarClienteWS(
        this.clienteSelecionado.codigo,
        this.clienteSelecionado.loja,
        jsonCorreto
      ).subscribe({
        next: (response) => {
          this.notification.success('Cliente atualizado com sucesso!');
        },
        error: (error) => {
          console.error('Erro ao atualizar:', error);
          this.notification.error('Erro: ' + error.message);
        }
      });
    }
  }
}
*/
