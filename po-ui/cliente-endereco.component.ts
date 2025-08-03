import { Component, OnInit } from '@angular/core';
import { PoNotificationService, PoPageAction, PoTableColumn, PoTableAction } from '@po-ui/ng-components';
import { ClienteEnderecoService } from './cliente-endereco.service';
import { ClienteModel } from './models/cliente.model';

@Component({
  selector: 'app-cliente-endereco',
  templateUrl: './cliente-endereco.component.html',
  styleUrls: ['./cliente-endereco.component.css']
})
export class ClienteEnderecoComponent implements OnInit {

  // Propriedades da tela
  clientes: ClienteModel[] = [];
  clienteSelecionado: ClienteModel = new ClienteModel();
  loading = false;
  showModal = false;
  modalTitle = 'Alterar Endereço';

  // Filtros de busca
  filtroNome = '';
  filtroCodigo = '';

  // Propriedades do formulário de endereço
  cepBusca = '';
  endereco = {
    cep: '',
    logradouro: '',
    bairro: '',
    localidade: '',
    uf: '',
    complemento: '',
    numero: ''
  };

  // Colunas da tabela
  columns: PoTableColumn[] = [
    { property: 'codigo', label: 'Código', width: '10%' },
    { property: 'loja', label: 'Loja', width: '8%' },
    { property: 'nome', label: 'Nome', width: '25%' },
    { property: 'endereco', label: 'Endereço', width: '20%' },
    { property: 'bairro', label: 'Bairro', width: '15%' },
    { property: 'cidade', label: 'Cidade', width: '15%' },
    { property: 'cep', label: 'CEP', width: '7%' }
  ];

  // Ações da tabela
  actions: PoTableAction[] = [
    {
      action: this.editarEndereco.bind(this),
      icon: 'po-icon-edit',
      label: 'Alterar Endereço',
      tooltip: 'Alterar endereço do cliente'
    }
  ];

  // Ações da página
  pageActions: PoPageAction[] = [
    {
      label: 'Buscar Clientes',
      action: this.buscarClientes.bind(this),
      icon: 'po-icon-search'
    },
    {
      label: 'Limpar Filtros',
      action: this.limparFiltros.bind(this),
      icon: 'po-icon-refresh'
    }
  ];

  constructor(
    private clienteService: ClienteEnderecoService,
    private notification: PoNotificationService
  ) { }

  ngOnInit(): void {
    this.buscarClientes();
  }

  /**
   * Buscar lista de clientes
   */
  buscarClientes(): void {
    this.loading = true;
    
    this.clienteService.buscarClientes(this.filtroCodigo, this.filtroNome)
      .subscribe({
        next: (response) => {
          this.clientes = response.data || [];
          this.loading = false;
          
          if (this.clientes.length === 0) {
            this.notification.information('Nenhum cliente encontrado com os filtros informados.');
          }
        },
        error: (error) => {
          console.error('Erro ao buscar clientes:', error);
          this.notification.error('Erro ao buscar clientes: ' + (error.error?.mensagem || 'Erro interno'));
          this.loading = false;
        }
      });
  }

  /**
   * Abrir modal para editar endereço
   */
  editarEndereco(cliente: ClienteModel): void {
    this.clienteSelecionado = { ...cliente };
    this.endereco = {
      cep: cliente.cep || '',
      logradouro: cliente.endereco || '',
      bairro: cliente.bairro || '',
      localidade: cliente.cidade || '',
      uf: cliente.estado || '',
      complemento: cliente.complemento || '',
      numero: cliente.numero || ''
    };
    this.cepBusca = cliente.cep || '';
    this.showModal = true;
  }

  /**
   * Buscar endereço pelo CEP via ViaCEP
   */
  buscarCEP(): void {
    if (!this.cepBusca || this.cepBusca.length < 8) {
      this.notification.warning('Informe um CEP válido com 8 dígitos.');
      return;
    }

    this.loading = true;
    
    this.clienteService.buscarCEP(this.cepBusca)
      .subscribe({
        next: (response) => {
          if (!response.erro) {
            this.endereco = {
              cep: this.cepBusca,
              logradouro: response.logradouro || '',
              bairro: response.bairro || '',
              localidade: response.localidade || '',
              uf: response.uf || '',
              complemento: this.endereco.complemento,
              numero: this.endereco.numero
            };
            this.notification.success('CEP encontrado com sucesso!');
          } else {
            this.notification.error('CEP não encontrado: ' + response.mensagem);
          }
          this.loading = false;
        },
        error: (error) => {
          console.error('Erro ao buscar CEP:', error);
          this.notification.error('Erro ao buscar CEP: ' + (error.error?.mensagem || 'Erro interno'));
          this.loading = false;
        }
      });
  }

  /**
   * Salvar alterações do endereço
   */
  salvarEndereco(): void {
    if (!this.validarEndereco()) {
      return;
    }

    this.loading = true;

    const dadosEndereco = {
      codigo: this.clienteSelecionado.codigo,
      loja: this.clienteSelecionado.loja,
      cep: this.endereco.cep,
      endereco: this.endereco.logradouro,
      bairro: this.endereco.bairro,
      cidade: this.endereco.localidade,
      estado: this.endereco.uf,
      complemento: this.endereco.complemento,
      numero: this.endereco.numero
    };

    this.clienteService.atualizarEndereco(dadosEndereco)
      .subscribe({
        next: (response) => {
          if (!response.erro) {
            this.notification.success('Endereço atualizado com sucesso!');
            this.fecharModal();
            this.buscarClientes(); // Atualizar lista
          } else {
            this.notification.error('Erro ao atualizar endereço: ' + response.mensagem);
          }
          this.loading = false;
        },
        error: (error) => {
          console.error('Erro ao atualizar endereço:', error);
          this.notification.error('Erro ao atualizar endereço: ' + (error.error?.mensagem || 'Erro interno'));
          this.loading = false;
        }
      });
  }

  /**
   * Atualizar endereço direto pelo CEP (usando o endpoint PATCH)
   */
  atualizarPorCEP(): void {
    if (!this.cepBusca || this.cepBusca.length < 8) {
      this.notification.warning('Informe um CEP válido com 8 dígitos.');
      return;
    }

    this.loading = true;

    this.clienteService.atualizarEnderecoCEP(
      this.clienteSelecionado.codigo,
      this.clienteSelecionado.loja,
      this.cepBusca
    ).subscribe({
      next: (response) => {
        if (!response.erro) {
          this.notification.success('Endereço atualizado via CEP com sucesso!');
          
          // Atualizar campos do formulário com os dados retornados
          if (response.dados_cep) {
            this.endereco = {
              cep: this.cepBusca,
              logradouro: response.dados_cep.logradouro || '',
              bairro: response.dados_cep.bairro || '',
              localidade: response.dados_cep.localidade || '',
              uf: response.dados_cep.uf || '',
              complemento: this.endereco.complemento,
              numero: this.endereco.numero
            };
          }
          
          this.buscarClientes(); // Atualizar lista
        } else {
          this.notification.error('Erro ao atualizar via CEP: ' + response.mensagem);
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Erro ao atualizar via CEP:', error);
        this.notification.error('Erro ao atualizar via CEP: ' + (error.error?.mensagem || 'Erro interno'));
        this.loading = false;
      }
    });
  }

  /**
   * Validar dados do endereço
   */
  private validarEndereco(): boolean {
    if (!this.endereco.cep) {
      this.notification.warning('CEP é obrigatório.');
      return false;
    }

    if (!this.endereco.logradouro) {
      this.notification.warning('Logradouro é obrigatório.');
      return false;
    }

    if (!this.endereco.bairro) {
      this.notification.warning('Bairro é obrigatório.');
      return false;
    }

    if (!this.endereco.localidade) {
      this.notification.warning('Cidade é obrigatória.');
      return false;
    }

    if (!this.endereco.uf) {
      this.notification.warning('Estado é obrigatório.');
      return false;
    }

    return true;
  }

  /**
   * Limpar filtros de busca
   */
  limparFiltros(): void {
    this.filtroNome = '';
    this.filtroCodigo = '';
    this.buscarClientes();
  }

  /**
   * Fechar modal
   */
  fecharModal(): void {
    this.showModal = false;
    this.clienteSelecionado = new ClienteModel();
    this.endereco = {
      cep: '',
      logradouro: '',
      bairro: '',
      localidade: '',
      uf: '',
      complemento: '',
      numero: ''
    };
    this.cepBusca = '';
  }

  /**
   * Formatador de CEP
   */
  formatarCEP(event: any): void {
    let valor = event.target.value.replace(/\D/g, '');
    if (valor.length > 8) {
      valor = valor.substring(0, 8);
    }
    if (valor.length > 5) {
      valor = valor.replace(/(\d{5})(\d{3})/, '$1-$2');
    }
    this.cepBusca = valor;
  }
}
