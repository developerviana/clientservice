export class ClienteModel {
  codigo: string = '';
  loja: string = '';
  nome: string = '';
  nreduz: string = '';
  tipo: string = '';
  pessoa: string = '';
  cgc: string = '';
  inscricao: string = '';
  endereco: string = '';
  numero: string = '';
  complemento: string = '';
  bairro: string = '';
  cidade: string = '';
  estado: string = '';
  cep: string = '';
  telefone: string = '';
  email: string = '';
  
  // Campos adicionais para controle
  ativo: boolean = true;
  dataInclusao?: Date;
  dataAlteracao?: Date;
  usuarioInclusao?: string;
  usuarioAlteracao?: string;

  constructor(data?: Partial<ClienteModel>) {
    if (data) {
      Object.assign(this, data);
    }
  }

  /**
   * Formatar CNPJ/CPF para exibição
   */
  get cgcFormatado(): string {
    if (!this.cgc) return '';
    
    const numeros = this.cgc.replace(/\D/g, '');
    
    if (numeros.length === 11) {
      // CPF: 000.000.000-00
      return numeros.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
    } else if (numeros.length === 14) {
      // CNPJ: 00.000.000/0000-00
      return numeros.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
    }
    
    return this.cgc;
  }

  /**
   * Formatar CEP para exibição
   */
  get cepFormatado(): string {
    if (!this.cep) return '';
    
    const numeros = this.cep.replace(/\D/g, '');
    
    if (numeros.length === 8) {
      return numeros.replace(/(\d{5})(\d{3})/, '$1-$2');
    }
    
    return this.cep;
  }

  /**
   * Formatar telefone para exibição
   */
  get telefoneFormatado(): string {
    if (!this.telefone) return '';
    
    const numeros = this.telefone.replace(/\D/g, '');
    
    if (numeros.length === 10) {
      // (00) 0000-0000
      return numeros.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
    } else if (numeros.length === 11) {
      // (00) 00000-0000
      return numeros.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    }
    
    return this.telefone;
  }

  /**
   * Retorna endereço completo formatado
   */
  get enderecoCompleto(): string {
    let endereco = this.endereco || '';
    
    if (this.numero) {
      endereco += `, ${this.numero}`;
    }
    
    if (this.complemento) {
      endereco += ` - ${this.complemento}`;
    }
    
    if (this.bairro) {
      endereco += ` - ${this.bairro}`;
    }
    
    if (this.cidade && this.estado) {
      endereco += ` - ${this.cidade}/${this.estado}`;
    }
    
    if (this.cep) {
      endereco += ` - ${this.cepFormatado}`;
    }
    
    return endereco;
  }

  /**
   * Retorna o tipo de pessoa formatado
   */
  get pessoaDescricao(): string {
    switch (this.pessoa) {
      case 'F':
        return 'Pessoa Física';
      case 'J':
        return 'Pessoa Jurídica';
      default:
        return this.pessoa || '';
    }
  }

  /**
   * Retorna o tipo de cliente formatado
   */
  get tipoDescricao(): string {
    switch (this.tipo) {
      case 'F':
        return 'Consumidor Final';
      case 'L':
        return 'Produtor Rural';
      case 'R':
        return 'Revendedor';
      case 'S':
        return 'Solidário';
      case 'X':
        return 'Exportação';
      default:
        return this.tipo || '';
    }
  }

  /**
   * Validar se os dados obrigatórios estão preenchidos
   */
  isValid(): boolean {
    return !!(
      this.codigo &&
      this.loja &&
      this.nome &&
      this.nreduz
    );
  }

  /**
   * Retorna os erros de validação
   */
  getValidationErrors(): string[] {
    const errors: string[] = [];

    if (!this.codigo) {
      errors.push('Código é obrigatório');
    }

    if (!this.loja) {
      errors.push('Loja é obrigatória');
    }

    if (!this.nome) {
      errors.push('Nome é obrigatório');
    }

    if (!this.nreduz) {
      errors.push('Nome reduzido é obrigatório');
    }

    if (this.cgc && !this.isValidCgc()) {
      errors.push('CNPJ/CPF inválido');
    }

    if (this.cep && !this.isValidCep()) {
      errors.push('CEP inválido');
    }

    if (this.email && !this.isValidEmail()) {
      errors.push('E-mail inválido');
    }

    return errors;
  }

  /**
   * Validar CNPJ/CPF
   */
  private isValidCgc(): boolean {
    if (!this.cgc) return true;

    const numeros = this.cgc.replace(/\D/g, '');

    if (numeros.length === 11) {
      return this.isValidCpf(numeros);
    } else if (numeros.length === 14) {
      return this.isValidCnpj(numeros);
    }

    return false;
  }

  /**
   * Validar CPF
   */
  private isValidCpf(cpf: string): boolean {
    if (cpf.length !== 11) return false;

    // Verifica se todos os dígitos são iguais
    if (/^(\d)\1{10}$/.test(cpf)) return false;

    let soma = 0;
    for (let i = 0; i < 9; i++) {
      soma += parseInt(cpf.charAt(i)) * (10 - i);
    }

    let resto = 11 - (soma % 11);
    if (resto === 10 || resto === 11) resto = 0;
    if (resto !== parseInt(cpf.charAt(9))) return false;

    soma = 0;
    for (let i = 0; i < 10; i++) {
      soma += parseInt(cpf.charAt(i)) * (11 - i);
    }

    resto = 11 - (soma % 11);
    if (resto === 10 || resto === 11) resto = 0;
    if (resto !== parseInt(cpf.charAt(10))) return false;

    return true;
  }

  /**
   * Validar CNPJ
   */
  private isValidCnpj(cnpj: string): boolean {
    if (cnpj.length !== 14) return false;

    // Verifica se todos os dígitos são iguais
    if (/^(\d)\1{13}$/.test(cnpj)) return false;

    let tamanho = cnpj.length - 2;
    let numeros = cnpj.substring(0, tamanho);
    let digitos = cnpj.substring(tamanho);
    let soma = 0;
    let pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
      soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
      if (pos < 2) pos = 9;
    }

    let resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
    if (resultado !== parseInt(digitos.charAt(0))) return false;

    tamanho = tamanho + 1;
    numeros = cnpj.substring(0, tamanho);
    soma = 0;
    pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
      soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
      if (pos < 2) pos = 9;
    }

    resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
    if (resultado !== parseInt(digitos.charAt(1))) return false;

    return true;
  }

  /**
   * Validar CEP
   */
  private isValidCep(): boolean {
    if (!this.cep) return true;
    const numeros = this.cep.replace(/\D/g, '');
    return numeros.length === 8;
  }

  /**
   * Validar e-mail
   */
  private isValidEmail(): boolean {
    if (!this.email) return true;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(this.email);
  }

  /**
   * Converter para objeto para envio à API
   */
  toApiObject(): any {
    return {
      codigo: this.codigo,
      loja: this.loja,
      nome: this.nome,
      nreduz: this.nreduz,
      tipo: this.tipo,
      pessoa: this.pessoa,
      cgc: this.cgc ? this.cgc.replace(/\D/g, '') : '',
      inscricao: this.inscricao,
      endereco: this.endereco,
      numero: this.numero,
      complemento: this.complemento,
      bairro: this.bairro,
      cidade: this.cidade,
      estado: this.estado,
      cep: this.cep ? this.cep.replace(/\D/g, '') : '',
      telefone: this.telefone ? this.telefone.replace(/\D/g, '') : '',
      email: this.email
    };
  }

  /**
   * Criar instância a partir de dados da API
   */
  static fromApiObject(data: any): ClienteModel {
    return new ClienteModel({
      codigo: data.A1_COD || data.codigo,
      loja: data.A1_LOJA || data.loja,
      nome: data.A1_NOME || data.nome,
      nreduz: data.A1_NREDUZ || data.nreduz,
      tipo: data.A1_TIPO || data.tipo,
      pessoa: data.A1_PESSOA || data.pessoa,
      cgc: data.A1_CGC || data.cgc,
      inscricao: data.A1_INSCR || data.inscricao,
      endereco: data.A1_END || data.endereco,
      numero: data.A1_NUM || data.numero,
      complemento: data.A1_COMPL || data.complemento,
      bairro: data.A1_BAIRRO || data.bairro,
      cidade: data.A1_MUN || data.cidade,
      estado: data.A1_EST || data.estado,
      cep: data.A1_CEP || data.cep,
      telefone: data.A1_TEL || data.telefone,
      email: data.A1_EMAIL || data.email
    });
  }
}
