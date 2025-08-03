# Sistema de Alteração de Endereços - Angular + PO-UI

Este projeto implementa uma aplicação Angular com PO-UI para alteração de endereços de clientes, integrada com webservice TOTVS Protheus.

## 🚀 Funcionalidades

- **Listagem de Clientes**: Busca e exibição de clientes com filtros
- **Alteração de Endereços**: Interface amigável para edição de endereços
- **Integração ViaCEP**: Busca automática de endereço por CEP
- **Integração Webservice**: Conexão com API TOTVS usando CRMA980
- **Validações**: Validação de campos obrigatórios e formatos
- **Responsivo**: Interface adaptável para diferentes dispositivos

## 🛠 Tecnologias

- **Angular 16+**: Framework frontend
- **PO-UI**: Biblioteca de componentes TOTVS
- **TypeScript**: Linguagem de programação
- **RxJS**: Biblioteca para programação reativa
- **HttpClient**: Cliente HTTP do Angular

## 📋 Pré-requisitos

- Node.js 16+
- Angular CLI
- NPM ou Yarn

## 🔧 Instalação

1. **Instalar dependências:**
```bash
npm install
```

2. **Configurar ambiente:**
   - Ajustar URL do webservice em `cliente-endereco.service.ts`
   - Configurar proxy se necessário

3. **Executar aplicação:**
```bash
npm start
```

4. **Acessar aplicação:**
   - URL: `http://localhost:4200`

## 📁 Estrutura do Projeto

```
po-ui/
├── models/
│   └── cliente.model.ts           # Modelo de dados do cliente
├── cliente-endereco.component.ts  # Componente principal
├── cliente-endereco.component.html # Template HTML
├── cliente-endereco.component.css  # Estilos CSS
├── cliente-endereco.service.ts     # Serviço de integração
├── cliente-endereco.module.ts      # Módulo Angular
├── package.json                    # Dependências do projeto
└── README.md                       # Documentação
```

## 🔌 Integração com Webservice

### Endpoints utilizados:

1. **GET /clientes** - Buscar lista de clientes
2. **PUT /clientes/{codigo}/{loja}** - Alterar dados do cliente
3. **PATCH /clientes/{codigo}/{loja}/cep/{cep}** - Atualizar endereço por CEP

### Configuração da URL:

```typescript
// cliente-endereco.service.ts
private readonly API_URL = '/rest/clientes'; // Ajustar conforme ambiente
```

## 📝 Como Usar

### 1. Buscar Clientes
- Digite código ou nome nos filtros
- Clique em "Buscar Clientes"

### 2. Alterar Endereço
- Clique no ícone de edição na linha do cliente
- No modal, escolha uma das opções:
  - **Buscar CEP**: Preenche automaticamente via ViaCEP
  - **Atualizar por CEP**: Aplica diretamente via webservice
  - **Manual**: Preencha os campos manualmente

### 3. Salvar Alterações
- Clique em "Salvar" para aplicar as alterações
- O sistema utilizará o MsExecAuto CRMA980

## 🎨 Componentes PO-UI Utilizados

- **po-page-default**: Página base com ações
- **po-table**: Tabela de clientes com ações
- **po-modal**: Modal para edição de endereço
- **po-input**: Campos de entrada
- **po-select**: Seleção de estado
- **po-button**: Botões de ação
- **po-widget**: Agrupamento de conteúdo
- **po-info**: Exibição de informações
- **po-notification**: Notificações ao usuário

## 🔍 Validações Implementadas

### Cliente:
- Código obrigatório
- Loja obrigatória
- Nome obrigatório
- Nome reduzido obrigatório

### Endereço:
- CEP obrigatório (8 dígitos)
- Logradouro obrigatório
- Bairro obrigatório
- Cidade obrigatória
- Estado obrigatório (2 caracteres)

### Formatos:
- CEP: 00000-000
- CNPJ: 00.000.000/0000-00
- CPF: 000.000.000-00
- Telefone: (00) 00000-0000

## 🚦 Tratamento de Erros

- **400**: Dados inválidos
- **404**: Cliente não encontrado
- **500**: Erro interno do servidor
- **0**: Erro de conexão

## 📱 Responsividade

A interface se adapta automaticamente para:
- **Desktop**: Layout completo
- **Tablet**: Ajuste de colunas
- **Mobile**: Layout empilhado

## 🔄 Fluxo de Integração

1. **Frontend (Angular)** ↔ **Webservice (TOTVS)**
2. **Webservice** ↔ **CRMA980 (MsExecAuto)**
3. **CRMA980** ↔ **SA1 (Tabela de Clientes)**
4. **ViaCEP** ↔ **Frontend (busca de endereço)**

## 🧪 Teste da Integração

### Teste de Inclusão:
```typescript
const cliente = {
  codigo: 'CLI001',
  loja: '01',
  nome: 'Cliente Teste',
  nreduz: 'Teste',
  cep: '01310-100'
};
```

### Teste de Alteração por CEP:
```http
PATCH /clientes/CLI001/01/cep/04038-001
```

## 📋 Checklist de Implementação

- ✅ Interface de listagem de clientes
- ✅ Modal de edição de endereço
- ✅ Integração com ViaCEP
- ✅ Conexão com webservice TOTVS
- ✅ Validações de campos
- ✅ Tratamento de erros
- ✅ Design responsivo
- ✅ Componentes PO-UI
- ✅ Documentação completa

## 🎯 Próximos Passos

1. Implementar testes unitários
2. Adicionar cache de dados
3. Implementar paginação
4. Adicionar exportação de relatórios
5. Implementar auditoria de alterações

## 📞 Suporte

Para dúvidas ou problemas:
- Consulte a documentação do PO-UI
- Verifique os logs do console
- Teste a conexão com o webservice
