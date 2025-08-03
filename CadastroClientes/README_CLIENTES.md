# Sistema de Cadastro de Clientes

Este módulo contém fontes para cadastro completo de clientes na tabela SA1 do Protheus.

## Arquivos Criados

### 1. CLICAD.prw (MVC Cadastro de Clientes)
- **Localização**: `/mvc/CLICAD.prw`
- **Função Principal**: `U_CLICAD()`
- **Descrição**: Interface MVC completa para cadastro de clientes

#### Funcionalidades:
- ✅ Visualizar clientes
- ✅ Incluir novos clientes
- ✅ Alterar clientes existentes
- ✅ Excluir clientes
- ✅ Consulta automática de CEP via ViaCEP
- ✅ Validações de campos (CNPJ/CPF, CEP, Email)
- ✅ Legendas por status do cliente
- ✅ Interface organizada por grupos de campos

#### Validações Implementadas:
- **Código**: Mínimo 3 caracteres
- **CNPJ/CPF**: Validação de formato (11 ou 14 dígitos)
- **CEP**: Exatamente 8 dígitos numéricos
- **Email**: Presença de @ e ponto

#### Legendas:
- 🔴 **Vermelho**: Cliente Bloqueado
- 🟡 **Amarelo**: Cliente sem CEP
- 🟢 **Verde**: Cliente Ativo

### 2. CADIMPORT.prw (Importação CSV)
- **Localização**: `/import/CADIMPORT.prw`
- **Função Principal**: `U_CADIMPORT()`
- **Descrição**: Importação em massa de clientes via arquivo CSV

#### Layout do CSV:
```
CODIGO;LOJA;NOME;NOMEREDUZIDO;TIPO;PESSOA;CNPJCPF;INSCRESTADUAL;CEP;ENDERECO;BAIRRO;CIDADE;UF;TELEFONE;EMAIL
```

#### Campos Obrigatórios:
- **CODIGO**: Código do cliente
- **LOJA**: Loja do cliente  
- **NOME**: Nome completo do cliente

#### Funcionalidades:
- ✅ Validação de cabeçalho do CSV
- ✅ Inclusão de novos clientes
- ✅ Atualização de clientes existentes
- ✅ Log detalhado de processamento
- ✅ Tratamento de erros
- ✅ Relatório final com estatísticas

### 3. exemplo_clientes.csv
- **Localização**: `/import/exemplo_clientes.csv`
- **Descrição**: Arquivo de exemplo com layout correto para importação

## Como Usar

### Cadastro MVC (CLICAD)
1. Execute a função `U_CLICAD()` no Protheus
2. Use o browse para navegar pelos clientes
3. Use os botões da barra de ferramentas para:
   - Incluir novos clientes
   - Alterar clientes existentes
   - Consultar CEP automaticamente
   - Importar via CSV

### Importação CSV (CADIMPORT)
1. Prepare seu arquivo CSV seguindo o layout do exemplo
2. Execute `U_CADIMPORT()` ou acesse via menu do CLICAD
3. Selecione o arquivo CSV
4. Acompanhe o processamento
5. Verifique o log gerado em `\temp\`

## Integrações

### Consulta de CEP
- Utiliza a API pública do ViaCEP
- Preenche automaticamente endereço completo
- Tratamento de erros e validações

### Logs
- Logs detalhados no console do Protheus
- Arquivo de log salvo automaticamente
- Estatísticas de importação

## Campos da Tabela SA1 Utilizados

| Campo | Descrição | Obrigatório |
|-------|-----------|-------------|
| A1_COD | Código do Cliente | Sim |
| A1_LOJA | Loja | Sim |
| A1_NOME | Nome | Sim |
| A1_NREDUZ | Nome Reduzido | Não |
| A1_TIPO | Tipo | Não |
| A1_PESSOA | Pessoa (F/J) | Não |
| A1_CGC | CNPJ/CPF | Não |
| A1_INSCR | Inscrição Estadual | Não |
| A1_CEP | CEP | Não |
| A1_END | Endereço | Não |
| A1_BAIRRO | Bairro | Não |
| A1_MUN | Município | Não |
| A1_EST | Estado | Não |
| A1_TEL | Telefone | Não |
| A1_EMAIL | Email | Não |

## Observações Importantes

1. **Backup**: Sempre faça backup antes de importações em massa
2. **Teste**: Teste primeiro com poucos registros
3. **Validação**: Verifique os dados antes da importação
4. **Performance**: Para grandes volumes, considere processar em lotes
5. **Log**: Sempre verifique os logs gerados

## Exemplo de Uso

```advpl
// Chamar o cadastro MVC
U_CLICAD()

// Chamar a importação CSV
U_CADIMPORT()

// Consultar CEP diretamente (dentro do MVC)
U_CADCONSULTACEP()
```

## Melhorias Futuras

- [ ] Validação avançada de CNPJ/CPF com dígito verificador
- [ ] Integração com outras APIs de endereço
- [ ] Importação via Excel
- [ ] Exportação de dados
- [ ] Dashboard de clientes
- [ ] Histórico de alterações
