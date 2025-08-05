# Client Services - Sistema de Gestão de Clientes

Este projeto implementa um sistema completo de gestão de clientes utilizando Protheus (ADVPL) e Angular com PO-UI, oferecendo uma solução moderna e integrada para operações CRUD de clientes.

## 📋 Visão Geral

O sistema é composto por quatro módulos principais:

1. **MVC (Model-View-Controller)** – Estrutura de dados e lógica de negócio
2. **WebService REST** – API para integração e operações remotas
3. **Programa de Importação** – Importação em lote de clientes
4. **Interface PO-UI** – Frontend moderno em Angular

## 🏗️ Arquitetura do Sistema

```
clientservices/
├── mvc/                    # Módulo MVC - Estrutura de dados
├── webservice/             # API REST - Serviços web
├── import/                 # Módulo de importação
└── po-ui/                  # Interface frontend
	└── EnderecoClienteManager/
```

## 📁 Módulos do Sistema

### 1. MVC (Model-View-Controller)

**Arquivos:**
- `CLICAD.prw` – Cadastro de clientes (View)
- `CLIMVC.prw` – Controlador MVC

**Funcionalidades:**
- Estruturação de dados seguindo padrão MVC
- Validações de negócio
- Integração com banco de dados Protheus
- Controle de transações

### 2. WebService REST

**Arquivos:**
- `WSCLIENTE.prw` – Endpoints REST principais
- `CLIENTESERVICE.prw` – Serviços de negócio
- `TESTECLIENTE.prw` – Testes automatizados

**Endpoints Disponíveis:**

- **POST /rest/WSCLIENTE/clientes** – Inclusão de novo cliente  
- **GET /rest/WSCLIENTE/clientes** – Listagem de todos os clientes  
- **PUT /rest/WSCLIENTE/{codigo}/{loja}** – Alteração de cliente existente  
- **DELETE /rest/WSCLIENTE/clientes** – Exclusão de cliente  

**Características Técnicas:**
- Padrão REST completo (GET, POST, PUT, DELETE)
- Validação de dados de entrada
- Tratamento de erros padronizado
- Logs detalhados para auditoria
- Integração com ViaCEP para busca de endereços
- Suporte a autenticação via token
- Comunicação em JSON

### Exemplos de retorno das APIs

**POST**
![POST retorno]([image.png](https://github.com/developerviana/clientservice/blob/main/img/image-1.png?raw=true))

**PUT**
![PUT retorno](image-1.png)

**DELETE**
![DELETE retorno](image-2.png)

**GET**
![GET retorno](image-3.png)


### 3. Programa de Importação

**Arquivo:**
- `CLIMPORT.prw` – Rotina de importação em lote

**Funcionalidades:**
- Importação de clientes via arquivo
- Validação de dados antes da importação
- Relatório de inconsistências
- Processamento em lote otimizado

### 4. Interface PO-UI (Angular)

**Estrutura:**
```
po-ui/EnderecoClienteManager/
├── src/
│   ├── app/
│   │   ├── components/         # Componentes da aplicação
│   │   ├── services/           # Serviços Angular
│   │   ├── models/             # Modelos de dados
│   │   └── guards/             # Guardas de rota
│   └── environments/           # Configurações ambiente
```

**Funcionalidades:**
- Interface moderna e responsiva
- Operações CRUD de clientes
- Modal de edição com campos específicos (Nome, Nome Reduzido, CEP, Endereço, Estado, Cidade, País)
- Integração completa com API REST
- Componentes PO-UI para UX consistente

## 🚀 Como Executar

### Pré-requisitos

**Backend (Protheus):**
- Protheus 12.1.33 ou superior
- Compilador ADVPL
- Acesso ao ambiente Protheus

**Frontend (Angular):**
- Node.js 16+
- Angular CLI 15+
- PO-UI instalado

### Instalação Backend

1. Compile os arquivos .prw no ambiente Protheus na ordem:
   - CLIMVC.prw (MVC)
   - CLIENTESERVICE.prw (Serviços)
   - WSCLIENTE.prw (WebService)
   - TESTECLIENTE.prw (Testes)
   - CLIMPORT.prw (Importação)

2. Configure o servidor REST no Protheus

3. Execute os testes:
   ```advpl
   U_TESTINSERT()     // Teste de inclusão
   U_TESTUPDATE()     // Teste de alteração
   U_TESTDELETE()     // Teste de exclusão
   U_TESTLIST()       // Teste de listagem
   ```

### Instalação Frontend

1. Acesse o diretório do projeto Angular:
   ```bash
   cd po-ui/EnderecoClienteManager
   ```
2. Instale as dependências:
   ```bash
   npm install
   ```
3. Execute o projeto:
   ```bash
   ng serve
   ```
4. Acesse: `http://localhost:4200`

## 🔧 Configuração da API

### Configuração do Proxy (proxy.conf.json)
```json
{
  "/rest/*": {
	"target": "http://localhost:8181",
	"secure": false,
	"changeOrigin": true,
	"logLevel": "debug"
  }
}
```

### Serviço Angular (cliente.service.ts)
```typescript
private apiUrl = 'http://localhost:8181/rest/WSCLIENTE';

atualizarCliente(codigo: string, loja: string, cliente: Cliente): Observable<any> {
  return this.http.put(`${this.apiUrl}/${codigo}/${loja}`, cliente);
}
```

## 🧪 Testes

### Testes Backend (ADVPL)
```advpl
// Menu principal de testes
U_MENUTESTE()

// Testes individuais
U_TESTINSERT()   // Inclusão
U_TESTUPDATE()   // Alteração
U_TESTDELETE()   // Exclusão
U_TESTLIST()     // Listagem
U_TESTVIACEP()   // Integração ViaCEP
```

### Exemplo de JSON para Testes
```json
{
  "codigo": "TST001",
  "loja": "01",
  "nome": "CLIENTE TESTE",
  "nomeReduzido": "TESTE",
  "tipoPessoa": "J",
  "tipo": "F",
  "endereco": "RUA TESTE, 123",
  "bairro": "CENTRO",
  "estado": "SP",
  "cidade": "SAO PAULO",
  "cep": "01310100",
  "cpfCnpj": "12345678000195",
  "pais": "105",
  "email": "teste@email.com",
  "ddd": "11",
  "telefone": "99887766"
}
```

## 📊 Recursos Técnicos

- Integração com ViaCEP para busca automática de endereço por CEP
- Validações de campos obrigatórios, CPF/CNPJ e CEP
- Logs detalhados e tratamento de erros padronizado
- Controle de permissões e autenticação por token
- Queries otimizadas, cache e paginação para performance

## 🤝 Contribuição

1. Faça fork do projeto
2. Crie sua feature branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a licença MIT – veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👥 Autores

- **Victor** – Desenvolvimento inicial – [@developerviana](https://github.com/developerviana)

---

