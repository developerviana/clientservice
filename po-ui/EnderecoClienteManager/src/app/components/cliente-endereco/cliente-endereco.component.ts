import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import {
  PoButtonModule,
  PoFieldModule,
  PoPageModule,
  PoModalModule,
  PoTableModule,
  PoNotificationService,
  PoTableColumn,
  PoTableAction,
  PoModalAction,
  PoPageAction
} from '@po-ui/ng-components';

import { ClienteEnderecoService } from '../../services/cliente-endereco.service';
import { AuthService } from '../../services/auth.service';
import { Cliente } from '../../models/cliente.model';

@Component({
  selector: 'app-cliente-endereco',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    PoButtonModule,
    PoFieldModule,
    PoPageModule,
    PoModalModule,
    PoTableModule
  ],
  templateUrl: './cliente-endereco.component.html',
  styleUrls: ['./cliente-endereco.component.scss']
})
export class ClienteEnderecoComponent implements OnInit {
  
  form!: FormGroup;
  clientes: Cliente[] = [];
  clienteSelecionado: Cliente | null = null;
  modalAberto = false;
  modalEditar = false;
  modalVisualizacao = false;
  modalCep = false;
  carregando = false;
  novoCep = '';
  usuarioLogado = 'admin';

  // Configurações da tabela
  tableColumns: PoTableColumn[] = [
    { property: 'codigo', label: 'Código', width: '10%' },
    { property: 'loja', label: 'Loja', width: '8%' },
    { property: 'endereco', label: 'Endereço', width: '25%' },
    { property: 'bairro', label: 'Bairro', width: '20%' },
    { property: 'cidade', label: 'Cidade', width: '15%' },
    { property: 'estado', label: 'Estado', width: '10%' },
    { property: 'cep', label: 'CEP', width: '12%' }
  ];

  tableActions: PoTableAction[] = [
    {
      action: this.editarEndereco.bind(this),
      label: 'Alterar',
      icon: 'po-icon-edit',
      type: 'primary'
    },
    {
      action: this.alterarPorCep.bind(this),
      label: 'Alterar por CEP',
      icon: 'po-icon-location',
      type: 'secondary'
    },
    {
      action: this.visualizarCliente.bind(this),
      label: 'Visualizar',
      icon: 'po-icon-eye',
      type: 'secondary'
    }
  ];

  pageActions: PoPageAction[] = [
    {
      label: 'Atualizar Lista',
      action: this.carregarClientes.bind(this),
      icon: 'po-icon-refresh'
    }
  ];

  modalActions: PoModalAction[] = [
    {
      label: 'Salvar',
      action: () => this.salvarEndereco(),
      danger: false
    },
    {
      label: 'Cancelar',
      action: () => this.fecharModal(),
      danger: true
    }
  ];

  constructor(
    private fb: FormBuilder,
    private clienteService: ClienteEnderecoService,
    private authService: AuthService,
    private router: Router,
    private notification: PoNotificationService
  ) {
    this.inicializarForm();
  }

  ngOnInit(): void {
    this.carregarClientes();
  }

  private inicializarForm(): void {
    this.form = this.fb.group({
      codigo: ['', Validators.required],
      loja: ['', Validators.required],
      nome: ['', Validators.required],
      cep: ['', [Validators.required, Validators.pattern(/^\d{5}-?\d{3}$/)]],
      endereco: ['', Validators.required],
      numero: [''],
      complemento: [''],
      bairro: ['', Validators.required],
      cidade: ['', Validators.required],
      estado: ['', [Validators.required, Validators.maxLength(2)]]
    });
  }

  carregarClientes(): void {
    console.log('🔄 Iniciando carregamento de clientes...');
    this.carregando = true;
    this.clienteService.listarClientes().subscribe({
      next: (response: any) => {
        console.log('📡 Resposta bruta da API:', response);
        console.log('📊 Tipo da resposta:', typeof response);
        console.log('📋 É array?', Array.isArray(response));
        
        // Verificar se a resposta tem a estrutura esperada
        if (response && response.dados && Array.isArray(response.dados)) {
          this.clientes = response.dados;
          console.log('✅ Dados extraídos:', this.clientes);
        } else if (Array.isArray(response)) {
          this.clientes = response;
          console.log('✅ Dados são array direto:', this.clientes);
        } else {
          console.log('❌ Estrutura de dados não reconhecida');
          this.clientes = [];
        }
        
        console.log('📝 Clientes finais:', this.clientes);
        console.log('📊 Quantidade de clientes:', this.clientes.length);
        console.log('🏷️ Colunas da tabela:', this.tableColumns);
        
        this.carregando = false;
      },
      error: (error: any) => {
        console.error('❌ Erro ao carregar clientes:', error);
        this.carregando = false;
        this.notification.error('Erro ao carregar lista de clientes');
      }
    });
  }

  atualizarLista(): void {
    this.carregarClientes();
  }

  editarEndereco(cliente: Cliente): void {
    this.clienteSelecionado = cliente;
    this.form.patchValue({
      codigo: cliente.codigo,
      loja: cliente.loja,
      nome: cliente.nome,
      cep: cliente.cep,
      endereco: cliente.endereco,
      numero: cliente.numero,
      complemento: cliente.complemento,
      bairro: cliente.bairro,
      cidade: cliente.cidade,
      estado: cliente.estado
    });
    this.modalAberto = true;
  }

  buscarCep(): void {
    const cep = this.form.get('cep')?.value?.replace(/\D/g, '');
    
    if (cep && cep.length === 8) {
      this.carregando = true;
      this.clienteService.buscarCep(cep).subscribe({
        next: (endereco: any) => {
          this.form.patchValue({
            endereco: endereco.logradouro,
            bairro: endereco.bairro,
            cidade: endereco.localidade,
            estado: endereco.uf
          });
          this.carregando = false;
          this.notification.success('Endereço encontrado!');
        },
        error: (error: any) => {
          console.error('Erro ao buscar CEP:', error);
          this.notification.warning('CEP não encontrado.');
          this.carregando = false;
        }
      });
    }
  }

  salvarEndereco(): void {
    if (this.form.valid && this.clienteSelecionado) {
      const dadosEndereco = this.form.value;
      this.carregando = true;

      this.clienteService.alterarCliente(
        this.clienteSelecionado.codigo,
        this.clienteSelecionado.loja,
        dadosEndereco
      ).subscribe({
        next: (response: any) => {
          this.notification.success('Endereço atualizado com sucesso!');
          this.fecharModal();
          this.carregarClientes();
          this.carregando = false;
        },
        error: (error: any) => {
          console.error('Erro ao salvar endereço:', error);
          this.notification.error('Erro ao salvar endereço.');
          this.carregando = false;
        }
      });
    } else {
      this.notification.warning('Preencha todos os campos obrigatórios.');
    }
  }

  fecharModal(): void {
    this.modalAberto = false;
    this.modalEditar = false;
    this.clienteSelecionado = null;
    this.form.reset();
  }

  formatarCep(event: any): void {
    let value = event.target.value.replace(/\D/g, '');
    if (value.length > 5) {
      value = value.replace(/^(\d{5})(\d{1,3})/, '$1-$2');
    }
    this.form.patchValue({ cep: value });
  }

  /**
   * Método para alterar endereço apenas por CEP
   */
  alterarPorCep(cliente: Cliente): void {
    this.clienteSelecionado = cliente;
    this.modalCep = true;
  }

  /**
   * Método para visualizar dados do cliente
   */
  visualizarCliente(cliente: Cliente): void {
    this.clienteSelecionado = cliente;
    this.form.patchValue({
      codigo: cliente.codigo,
      loja: cliente.loja,
      nome: cliente.nome,
      cep: cliente.cep,
      endereco: cliente.endereco,
      numero: cliente.numero,
      complemento: cliente.complemento,
      bairro: cliente.bairro,
      cidade: cliente.cidade,
      estado: cliente.estado
    });
    this.modalVisualizacao = true;
  }

  /**
   * Atualiza endereço apenas via CEP (sem abrir modal completo)
   */
  atualizarApenasCep(cep: string): void {
    if (!cep || cep.length < 8) {
      this.notification.warning('Digite um CEP válido');
      return;
    }

    if (!this.clienteSelecionado) {
      this.notification.error('Nenhum cliente selecionado');
      return;
    }

    // Remove formatação do CEP
    const cepLimpo = cep.replace(/\D/g, '');
    
    this.carregando = true;
    
    // Primeiro busca o endereço pelo CEP
    this.clienteService.buscarCep(cepLimpo).subscribe({
      next: (endereco: any) => {
        // Monta os dados do endereço
        const dadosEndereco = {
          cep: cepLimpo,
          endereco: endereco.logradouro || '',
          bairro: endereco.bairro || '',
          cidade: endereco.localidade || '',
          estado: endereco.uf || ''
        };

        // Atualiza o cliente com o novo endereço
        this.clienteService.alterarCliente(
          this.clienteSelecionado!.codigo,
          this.clienteSelecionado!.loja,
          dadosEndereco
        ).subscribe({
          next: (response: any) => {
            this.notification.success('Endereço atualizado com sucesso pelo CEP!');
            this.fecharModalCep();
            this.carregarClientes();
            this.carregando = false;
          },
          error: (error: any) => {
            console.error('Erro ao atualizar endereço:', error);
            this.notification.error('Erro ao atualizar endereço.');
            this.carregando = false;
          }
        });
      },
      error: (error: any) => {
        console.error('Erro ao buscar CEP:', error);
        this.notification.warning('CEP não encontrado.');
        this.carregando = false;
      }
    });
  }

  /**
   * Fecha modal de visualização
   */
  fecharModalVisualizacao(): void {
    this.modalVisualizacao = false;
    this.clienteSelecionado = null;
  }

  /**
   * Fecha modal de CEP
   */
  fecharModalCep(): void {
    this.modalCep = false;
    this.clienteSelecionado = null;
    this.novoCep = '';
  }

  /**
   * Faz logout e redireciona para tela de login
   */
  logout(): void {
    this.authService.logout();
    this.notification.success('Logout realizado com sucesso!');
    this.router.navigate(['/login']);
  }

  /**
   * Busca endereço automaticamente quando CEP é alterado
   */
  buscarEnderecoPorCep(cep: string): void {
    if (cep && cep.replace(/\D/g, '').length === 8) {
      this.carregando = true;
      this.clienteService.buscarCep(cep).subscribe({
        next: (endereco: any) => {
          this.form.patchValue({
            endereco: endereco.logradouro,
            bairro: endereco.bairro,
            cidade: endereco.localidade,
            estado: endereco.uf
          });
          this.carregando = false;
          this.notification.success('Endereço encontrado!');
        },
        error: (error: any) => {
          console.error('Erro ao buscar CEP:', error);
          this.notification.warning('CEP não encontrado.');
          this.carregando = false;
        }
      });
    }
  }
}
