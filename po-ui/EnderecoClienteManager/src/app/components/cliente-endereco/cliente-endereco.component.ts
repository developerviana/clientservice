import { Component, OnInit, ChangeDetectorRef, ViewChild } from '@angular/core';
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
  PoModalAction,
  PoModalComponent
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
  
  // ViewChild para acessar os modais seguindo a documentação do PO-UI
  @ViewChild('modalIncluir', { static: false }) modalIncluir!: PoModalComponent;
  @ViewChild('modalEditar', { static: false }) modalEditar!: PoModalComponent;
  @ViewChild('modalExcluir', { static: false }) modalExcluir!: PoModalComponent;
  
  // Formulários
  form!: FormGroup;
  formAlterarWS!: FormGroup;
  formIncluir!: FormGroup;
  
  // Dados
  clientes: Cliente[] = [];
  clienteSelecionado: Cliente | null = null;
  carregando = false;
  usuarioLogado = 'admin';
  
  // Para compatibilidade com modais antigos
  modalAberto = false;
  modalCep = false;
  novoCep = '';

  // Configurações da tabela
  tableColumns: PoTableColumn[] = [
    { property: 'codigo', label: 'Código', width: '10%' },
    { property: 'loja', label: 'Loja', width: '8%' },
    { property: 'nome', label: 'Nome', width: '14%' },
    { property: 'endereco', label: 'Endereço', width: '23%' },
    { property: 'bairro', label: 'Bairro', width: '16%' },
    { property: 'municipio', label: 'Município', width: '11%' },
    { property: 'estado', label: 'Estado', width: '10%' },
    { property: 'cep', label: 'CEP', width: '8%' }
  ];

  // Ações dos modais seguindo exatamente a documentação do PO-UI
  acaoSalvarInclusao: PoModalAction = {
    label: 'Salvar',
    action: () => this.salvarNovoCliente(),
    loading: false
  };

  acaoSalvarEdicao: PoModalAction = {
    label: 'Salvar',
    action: () => this.salvarClienteWS(),
    loading: false
  };

  acaoConfirmarExclusao: PoModalAction = {
    label: 'Excluir',
    action: () => this.confirmarExclusao(),
    danger: true,
    loading: false
  };

  acaoCancelar: PoModalAction = {
    label: 'Cancelar',
    action: () => this.fecharTodosModais()
  };

  constructor(
    private fb: FormBuilder,
    private clienteService: ClienteEnderecoService,
    private authService: AuthService,
    private router: Router,
    private notification: PoNotificationService,
    private cdr: ChangeDetectorRef
  ) {
    this.inicializarForms();
  }

  ngOnInit(): void {
    this.carregarClientes();
  }

  private inicializarForms(): void {
    // Form para inclusão
    this.formIncluir = this.fb.group({
      codigo: ['', Validators.required],
      loja: ['', Validators.required],
      nome: ['', Validators.required],
      fantasia: [''],
      cpf: ['', Validators.required],
      cep: [''],
      endereco: [''],
      bairro: [''],
      cidade: [''],
      estado: ['']
    });

    // Form para edição
    this.formAlterarWS = this.fb.group({
      nome: ['', Validators.required],
      nomeReduzido: ['', Validators.required],
      cep: [''],
      endereco: [''],
      cidade: [''],
      estado: [''],
      pais: ['105']
    });

    // Form principal (para compatibilidade)
    this.form = this.fb.group({
      codigo: ['', Validators.required],
      loja: ['', Validators.required],
      nome: ['', Validators.required],
      cep: ['', [Validators.required, Validators.pattern(/^\d{5}-?\d{3}$/)]],
      endereco: ['', Validators.required],
      numero: [''],
      complemento: [''],
      bairro: ['', Validators.required],
      municipio: ['', Validators.required],
      estado: ['', [Validators.required, Validators.maxLength(2)]]
    });
  }

  // Métodos para abrir modais seguindo a documentação do PO-UI
  abrirModalIncluir(): void {
    this.formIncluir.reset();
    this.modalIncluir.open();
  }

  abrirModalEditar(): void {
    if (this.clienteSelecionado) {
      this.formAlterarWS.patchValue({
        nome: this.clienteSelecionado.nome || '',
        nomeReduzido: this.clienteSelecionado.nome?.substring(0, 15) || '',
        cep: this.clienteSelecionado.cep || '',
        endereco: this.clienteSelecionado.endereco || '',
        cidade: this.clienteSelecionado.municipio || '',
        estado: this.clienteSelecionado.estado || '',
        pais: '105'
      });
      this.modalEditar.open();
    } else {
      this.notification.warning('Selecione um cliente para editar.');
    }
  }

  abrirModalExcluir(): void {
    if (this.clienteSelecionado) {
      this.modalExcluir.open();
    } else {
      this.notification.warning('Selecione um cliente para excluir.');
    }
  }

  // Método para fechar todos os modais
  fecharTodosModais(): void {
    this.modalIncluir?.close();
    this.modalEditar?.close();
    this.modalExcluir?.close();
  }

  // Método para salvar novo cliente
  salvarNovoCliente(): void {
    if (this.formIncluir.valid) {
      this.carregando = true;
      this.acaoSalvarInclusao.loading = true;
      
      const novoCliente = this.formIncluir.value;
      
      this.clienteService.incluirCliente(novoCliente).subscribe({
        next: (response: any) => {
          this.notification.success('Cliente incluído com sucesso!');
          this.fecharTodosModais();
          this.carregarClientes();
          this.carregando = false;
          this.acaoSalvarInclusao.loading = false;
        },
        error: (error: any) => {
          this.notification.error('Erro ao incluir cliente: ' + (error.message || 'Erro desconhecido'));
          this.carregando = false;
          this.acaoSalvarInclusao.loading = false;
        }
      });
    } else {
      this.notification.warning('Preencha todos os campos obrigatórios.');
    }
  }

  // Método para salvar edição de cliente
  salvarClienteWS(): void {
    if (this.formAlterarWS.valid && this.clienteSelecionado) {
      this.carregando = true;
      this.acaoSalvarEdicao.loading = true;
      
      const dados = this.formAlterarWS.value;
      
      this.clienteService.alterarClienteWS(
        this.clienteSelecionado.codigo,
        this.clienteSelecionado.loja,
        dados
      ).subscribe({
        next: (response: any) => {
          this.notification.success('Cliente atualizado com sucesso!');
          this.fecharTodosModais();
          this.carregarClientes();
          this.carregando = false;
          this.acaoSalvarEdicao.loading = false;
        },
        error: (error: any) => {
          this.notification.error('Erro ao atualizar cliente: ' + (error.message || 'Erro desconhecido'));
          this.carregando = false;
          this.acaoSalvarEdicao.loading = false;
        }
      });
    } else {
      this.notification.warning('Preencha todos os campos obrigatórios.');
    }
  }

  // Método para confirmar exclusão
  confirmarExclusao(): void {
    if (this.clienteSelecionado) {
      this.carregando = true;
      this.acaoConfirmarExclusao.loading = true;
      
      this.clienteService.excluirCliente(
        this.clienteSelecionado.codigo,
        this.clienteSelecionado.loja
      ).subscribe({
        next: (response: any) => {
          this.notification.success('Cliente excluído com sucesso!');
          this.fecharTodosModais();
          this.clienteSelecionado = null;
          this.carregarClientes();
          this.carregando = false;
          this.acaoConfirmarExclusao.loading = false;
        },
        error: (error: any) => {
          this.notification.error('Erro ao excluir cliente: ' + (error.message || 'Erro desconhecido'));
          this.carregando = false;
          this.acaoConfirmarExclusao.loading = false;
        }
      });
    }
  }

  // Método para selecionar cliente na tabela
  selecionarCliente(cliente: Cliente): void {
    this.clienteSelecionado = cliente;
  }

  // Método para carregar lista de clientes
  carregarClientes(): void {
    this.carregando = true;
    this.clienteService.listarClientes().subscribe({
      next: (response: any) => {
        if (response && response.dados && Array.isArray(response.dados)) {
          this.clientes = response.dados;
        } else if (Array.isArray(response)) {
          this.clientes = response;
        } else {
          this.clientes = [];
        }
        this.carregando = false;
      },
      error: (error: any) => {
        this.carregando = false;
        this.notification.error('Erro ao carregar lista de clientes');
      }
    });
  }

  // Método para atualizar lista
  atualizarLista(): void {
    this.carregarClientes();
  }

  // Método para testar conexão com API
  testarConexaoApi(): void {
    console.log('🔄 Testando conexão com API...');
    this.carregando = true;
    
    // Teste simples fazendo GET nos clientes
    this.clienteService.listarClientes().subscribe({
      next: (response: any) => {
        console.log('✅ API funcionando! Resposta:', response);
        this.notification.success('✅ Conexão com API funcionando!');
        this.carregando = false;
      },
      error: (error: any) => {
        console.error('❌ Erro na API:', error);
        this.notification.error('❌ Erro na conexão: ' + error.message);
        this.carregando = false;
      }
    });
  }

  // Método para logout
  logout(): void {
    this.authService.logout();
    this.notification.success('Logout realizado com sucesso!');
    this.router.navigate(['/login']);
  }

  // Métodos para compatibilidade com modais antigos
  fecharModal(): void {
    this.modalAberto = false;
    this.modalCep = false;
  }

  fecharModalCep(): void {
    this.modalCep = false;
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
      municipio: cliente.municipio,
      estado: cliente.estado
    });
    this.modalAberto = true;
  }

  salvarEndereco(): void {
    if (this.form.valid && this.clienteSelecionado) {
      this.carregando = true;
      
      const dadosEndereco = {
        cep: this.form.value.cep?.replace(/\D/g, ''),
        endereco: this.form.value.endereco,
        numero: this.form.value.numero,
        complemento: this.form.value.complemento,
        bairro: this.form.value.bairro,
        municipio: this.form.value.municipio,
        estado: this.form.value.estado
      };

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
          this.notification.error('Erro ao atualizar endereço.');
          this.carregando = false;
        }
      });
    } else {
      this.notification.warning('Preencha todos os campos obrigatórios.');
    }
  }

  buscarEnderecoPorCep(cep: string): void {
    if (cep && cep.replace(/\D/g, '').length === 8) {
      this.carregando = true;
      this.clienteService.buscarCep(cep).subscribe({
        next: (endereco: any) => {
          this.form.patchValue({
            endereco: endereco.logradouro,
            bairro: endereco.bairro,
            municipio: endereco.localidade,
            estado: endereco.uf
          });
          this.carregando = false;
          this.notification.success('Endereço encontrado!');
        },
        error: (error: any) => {
          this.notification.warning('CEP não encontrado.');
          this.carregando = false;
        }
      });
    }
  }

  alterarPorCep(cliente: Cliente): void {
    this.clienteSelecionado = cliente;
    this.modalCep = true;
  }

  atualizarApenasCep(cep: string): void {
    if (!cep || cep.length < 8) {
      this.notification.warning('Digite um CEP válido');
      return;
    }

    if (!this.clienteSelecionado) {
      this.notification.error('Nenhum cliente selecionado');
      return;
    }

    const cepLimpo = cep.replace(/\D/g, '');
    this.carregando = true;
    
    this.clienteService.buscarCep(cepLimpo).subscribe({
      next: (endereco: any) => {
        const dadosEndereco = {
          cep: cepLimpo,
          endereco: endereco.logradouro || '',
          municipio: endereco.localidade || '',
          estado: endereco.uf || ''
        };

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
            this.notification.error('Erro ao atualizar endereço.');
            this.carregando = false;
          }
        });
      },
      error: (error: any) => {
        this.notification.warning('CEP não encontrado.');
        this.carregando = false;
      }
    });
  }
}
