export interface Cliente {
  codigo: string;
  loja: string;
  endereco: string;
  bairro: string;
  estado: string;
  cep: string;
  // Campos opcionais que podem vir de outras APIs
  nome?: string;
  tipo?: string;
  cnpjCpf?: string;
  inscricaoEstadual?: string;
  numero?: string;
  complemento?: string;
  cidade?: string;
  telefone?: string;
  email?: string;
  observacoes?: string;
  ativo?: boolean;
  dataCadastro?: Date;
  dataUltimaAlteracao?: Date;
}

export interface ClienteForm {
  codigo: string;
  loja: string;
  nome: string;
  tipo: 'F' | 'J'; // F = Física, J = Jurídica
  cnpjCpf: string;
  inscricaoEstadual?: string;
  endereco: string;
  numero?: string;
  complemento?: string;
  bairro: string;
  cidade: string;
  estado: string;
  cep: string;
  telefone?: string;
  email?: string;
  observacoes?: string;
}

export interface EnderecoViaCep {
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

export interface ClienteFilter {
  codigo?: string;
  loja?: string;
  nome?: string;
  cidade?: string;
  estado?: string;
  ativo?: boolean;
}

export interface ClienteResponse {
  sucesso: boolean;
  dados: Cliente[];
  total: number;
  mensagem?: string;
}

export interface ClienteSingleResponse {
  sucesso: boolean;
  dados: Cliente;
  mensagem?: string;
}

export class ClienteValidator {
  
  static validarCNPJ(cnpj: string): boolean {
    cnpj = cnpj.replace(/[^\d]+/g, '');
    
    if (cnpj === '' || cnpj.length !== 14) return false;
    
    if (/^(\d)\1+$/.test(cnpj)) return false;
    
    let tamanho = cnpj.length - 2;
    let numeros = cnpj.substring(0, tamanho);
    let digitos = cnpj.substring(tamanho);
    let soma = 0;
    let pos = tamanho - 7;
    
    for (let i = tamanho; i >= 1; i--) {
      soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
      if (pos < 2) pos = 9;
    }
    
    let resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
    if (resultado !== parseInt(digitos.charAt(0))) return false;
    
    tamanho = tamanho + 1;
    numeros = cnpj.substring(0, tamanho);
    soma = 0;
    pos = tamanho - 7;
    
    for (let i = tamanho; i >= 1; i--) {
      soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
      if (pos < 2) pos = 9;
    }
    
    resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
    return resultado === parseInt(digitos.charAt(1));
  }
  
  static validarCPF(cpf: string): boolean {
    cpf = cpf.replace(/[^\d]+/g, '');
    
    if (cpf === '' || cpf.length !== 11) return false;
    
    if (/^(\d)\1+$/.test(cpf)) return false;
    
    let soma = 0;
    for (let i = 1; i <= 9; i++) {
      soma = soma + parseInt(cpf.substring(i - 1, i)) * (11 - i);
    }
    
    let resto = (soma * 10) % 11;
    if ((resto === 10) || (resto === 11)) resto = 0;
    if (resto !== parseInt(cpf.substring(9, 10))) return false;
    
    soma = 0;
    for (let i = 1; i <= 10; i++) {
      soma = soma + parseInt(cpf.substring(i - 1, i)) * (12 - i);
    }
    
    resto = (soma * 10) % 11;
    if ((resto === 10) || (resto === 11)) resto = 0;
    return resto === parseInt(cpf.substring(10, 11));
  }
  
  static validarCEP(cep: string): boolean {
    const cepRegex = /^\d{5}-?\d{3}$/;
    return cepRegex.test(cep);
  }
  
  static formatarCNPJ(cnpj: string): string {
    cnpj = cnpj.replace(/\D/g, '');
    return cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  }
  
  static formatarCPF(cpf: string): string {
    cpf = cpf.replace(/\D/g, '');
    return cpf.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, '$1.$2.$3-$4');
  }
  
  static formatarCEP(cep: string): string {
    cep = cep.replace(/\D/g, '');
    return cep.replace(/^(\d{5})(\d{3})$/, '$1-$2');
  }
}
