# Manutenção de Endereços de Clientes

#### MVC (mvc/)
- Tela principal com browse de clientes
- Visualização com legendas de status
- Atualização manual por CEP
- Importação via CSV
- Navegação e interface SmartClient

#### REST API (rest/)
- **Controller**: Endpoints para receber requisições JSON
- **Service**: Lógica de negócio e chamadas MsExecAuto
- Validações e tratamento de erros
- Logs no console (CONOUT)

#### WebServices (webservices/)
- Integração com ViaCEP
- Consumo de API externa
- Tratamento de respostas JSON

#### Importação (importacao/)
- Processamento de arquivos CSV
- Validação de layout e cabeçalho
- Atualização em massa
- Tratamento de erros por registro

### 📋 Campos Utilizados (SA1)
- A1_COD, A1_LOJA, A1_NOME
- A1_CEP, A1_EST, A1_MUN
- A1_END, A1_BAIRRO, A1_COMPLEM

### 🎨 Legendas de Status
- 🔴 **Vermelha**: A1_CEP em branco
- 🟡 **Amarela**: A1_CEP preenchido, demais campos vazios
- 🟢 **Verde**: Todos os campos de endereço preenchidos

### 🌐 Integrações
- **ViaCEP**: `https://viacep.com.br/ws/{cep}/json/`
- **MsExecAuto**: CRMA980 para atualização de clientes
- **CSV**: Layout com separador `;` (ponto e vírgula)
