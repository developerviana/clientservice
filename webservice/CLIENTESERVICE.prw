#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  CLIENTESERVICE
//Autor:     Victor
//Descricao: Service para operações de cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/

CLASS ClienteMsExecService

    METHOD New() CONSTRUCTOR
    METHOD IncluirCliente(oRequest)
    METHOD AlterarCliente(oRequest)
    METHOD ExcluirCliente(cCodigo, cLoja)
    METHOD AtualizarEnderecoCEP(cCodigo, cLoja, cCEP)
    METHOD BuscarEnderecoCEP(cCEP)
    METHOD ValidarDados(oRequest, nOpcao)
    METHOD MontarArrayCRMA980(oRequest, nOpcao)

ENDCLASS

/*------------------------------------------------------------------------//
// Construtor
//------------------------------------------------------------------------*/
METHOD New() CLASS ClienteMsExecService
Return Self

/*------------------------------------------------------------------------//
// Incluir cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD IncluirCliente(oRequest) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente  := {}
    Local cErro     := ""

    ConOut("[SERVICE][INCLUIR] Iniciando inclusão via CRMA980")

    Try
        // Validar dados obrigatórios
        cErro := Self:ValidarDados(oRequest, 3) // 3 = Inclusão
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            Return oResponse
        EndIf

        // Verificar se cliente já existe
        SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
        If SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Cliente já existe: " + oRequest["codigo"] + "-" + oRequest["loja"]
            Return oResponse
        EndIf

        // Se informou CEP, busca endereço completo
        If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
            Local oEndereco := Self:BuscarEnderecoCEP(oRequest["cep"])
            If !oEndereco["erro"]
                oRequest["endereco"] := oEndereco["logradouro"]
                oRequest["bairro"] := oEndereco["bairro"]
                oRequest["cidade"] := oEndereco["localidade"]
                oRequest["estado"] := oEndereco["uf"]
            EndIf
        EndIf

        // Montar array para MsExecAuto CRMA980
        aCliente := Self:MontarArrayCRMA980(oRequest, 3)
        
        ConOut("[SERVICE][INCLUIR] Array CRMA980 montado com " + cValToChar(Len(aCliente)) + " itens")

        // Chamar MsExecAuto CRMA980
        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 3)

        If lMsErroAuto
            cErro := "Erro no MsExecAuto CRMA980"
            ConOut("[SERVICE][INCLUIR][ERRO] " + cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
        Else
            ConOut("[SERVICE][INCLUIR] Sucesso: " + oRequest["codigo"] + "-" + oRequest["loja"])
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente incluído com sucesso via CRMA980"
            oResponse["codigo"] := oRequest["codigo"]
            oResponse["loja"] := oRequest["loja"]
            oResponse["nome"] := oRequest["nome"]
        EndIf

    Catch oError
        ConOut("[SERVICE][INCLUIR][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    End

Return oResponse

/*------------------------------------------------------------------------//
// Alterar cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD AlterarCliente(oRequest) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente  := {}
    Local cErro     := ""

    ConOut("[SERVICE][ALTERAR] Iniciando alteração via CRMA980")

    Try
        // Validar dados obrigatórios
        cErro := Self:ValidarDados(oRequest, 4) // 4 = Alteração
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            Return oResponse
        EndIf

        // Verificar se cliente existe
        SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente não encontrado: " + oRequest["codigo"] + "-" + oRequest["loja"]
            Return oResponse
        EndIf

        // Se informou CEP, busca endereço completo
        If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
            Local oEndereco := Self:BuscarEnderecoCEP(oRequest["cep"])
            If !oEndereco["erro"]
                oRequest["endereco"] := oEndereco["logradouro"]
                oRequest["bairro"] := oEndereco["bairro"]
                oRequest["cidade"] := oEndereco["localidade"]
                oRequest["estado"] := oEndereco["uf"]
            EndIf
        EndIf

        // Montar array para MsExecAuto CRMA980
        aCliente := Self:MontarArrayCRMA980(oRequest, 4)
        
        ConOut("[SERVICE][ALTERAR] Array CRMA980 montado com " + cValToChar(Len(aCliente)) + " itens")

        // Chamar MsExecAuto CRMA980
        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 4)

        If lMsErroAuto
            cErro := "Erro no MsExecAuto CRMA980"
            ConOut("[SERVICE][ALTERAR][ERRO] " + cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
        Else
            ConOut("[SERVICE][ALTERAR] Sucesso: " + oRequest["codigo"] + "-" + oRequest["loja"])
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente alterado com sucesso via CRMA980"
            oResponse["codigo"] := oRequest["codigo"]
            oResponse["loja"] := oRequest["loja"]
            oResponse["nome"] := oRequest["nome"]
        EndIf

    Catch oError
        ConOut("[SERVICE][ALTERAR][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    End

Return oResponse

/*------------------------------------------------------------------------//
// Excluir cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD ExcluirCliente(cCodigo, cLoja) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente  := {}
    Local cErro     := ""

    ConOut("[SERVICE][EXCLUIR] Iniciando exclusão via CRMA980")

    Try
        If Empty(cCodigo) .Or. Empty(cLoja)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Código e Loja obrigatórios"
            Return oResponse
        EndIf

        // Verificar se cliente existe
        SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente não encontrado: " + cCodigo + "-" + cLoja
            Return oResponse
        EndIf

        // Montar array básico para exclusão CRMA980
        aCliente := {{"A1_COD", cCodigo, Nil}}
        
        ConOut("[SERVICE][EXCLUIR] Array CRMA980 montado para exclusão")

        // Chamar MsExecAuto CRMA980
        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 5)

        If lMsErroAuto
            cErro := "Erro no MsExecAuto CRMA980"
            ConOut("[SERVICE][EXCLUIR][ERRO] " + cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
        Else
            ConOut("[SERVICE][EXCLUIR] Sucesso: " + cCodigo + "-" + cLoja)
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente excluído com sucesso via CRMA980"
            oResponse["codigo"] := cCodigo
            oResponse["loja"] := cLoja
        EndIf

    Catch oError
        ConOut("[SERVICE][EXCLUIR][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    End

Return oResponse

/*------------------------------------------------------------------------//
// Atualizar endereço do cliente baseado no CEP
//------------------------------------------------------------------------*/
METHOD AtualizarEnderecoCEP(cCodigo, cLoja, cCEP) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local oEndereco := Nil
    Local oRequest  := JsonObject():New()

    ConOut("[SERVICE][ATUALIZAR_CEP] Atualizando endereço via CEP: " + cCEP)

    Try
        // Buscar dados do CEP
        oEndereco := Self:BuscarEnderecoCEP(cCEP)
        
        If oEndereco["erro"]
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro ao buscar CEP: " + oEndereco["mensagem"]
            Return oResponse
        EndIf

        // Montar request para alteração
        oRequest["codigo"] := cCodigo
        oRequest["loja"] := cLoja
        oRequest["cep"] := cCEP
        oRequest["endereco"] := oEndereco["logradouro"]
        oRequest["bairro"] := oEndereco["bairro"]
        oRequest["cidade"] := oEndereco["localidade"]
        oRequest["estado"] := oEndereco["uf"]

        // Alterar cliente com novos dados
        oResponse := Self:AlterarCliente(oRequest)

        If !oResponse["erro"]
            oResponse["endereco_atualizado"] := .T.
            oResponse["dados_cep"] := oEndereco
        EndIf

    Catch oError
        ConOut("[SERVICE][ATUALIZAR_CEP][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    End

Return oResponse

/*------------------------------------------------------------------------//
// Buscar endereço via ViaCEP
//------------------------------------------------------------------------*/
METHOD BuscarEnderecoCEP(cCEP) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local oRest     := Nil
    Local cUrl      := ""
    Local cJson     := ""

    ConOut("[SERVICE][VIACEP] Buscando CEP: " + cCEP)

    Try
        // Limpar CEP
        cCEP := StrTran(StrTran(cCEP, "-", ""), ".", "")
        
        If Len(cCEP) != 8
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "CEP deve ter 8 dígitos"
            Return oResponse
        EndIf

        // Preparar URL ViaCEP
        cUrl := "https://viacep.com.br/ws/" + cCEP + "/json/"
        
        // Criar objeto REST
        oRest := FWRest():New()
        oRest:SetPath(cUrl)

        // Fazer requisição GET
        If oRest:Get()
            cJson := oRest:GetResult()
            ConOut("[SERVICE][VIACEP] Resposta: " + cJson)
            
            oResponse:FromJson(cJson)
            
            // Verificar se CEP é válido
            If oResponse:HasProperty("erro") .And. oResponse["erro"]
                oResponse["erro"] := .T.
                oResponse["mensagem"] := "CEP não encontrado"
                Return oResponse
            EndIf
            
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "CEP encontrado com sucesso"
            
        Else
            ConOut("[SERVICE][VIACEP][ERRO] Falha na requisição")
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro ao consultar ViaCEP: " + oRest:GetLastError()
        EndIf

    Catch oError
        ConOut("[SERVICE][VIACEP][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno ao consultar CEP: " + oError:Description
    End

Return oResponse

/*------------------------------------------------------------------------//
// Validar dados obrigatórios
//------------------------------------------------------------------------*/
METHOD ValidarDados(oRequest, nOpcao) CLASS ClienteMsExecService
    Local cErro := ""

    If nOpcao == 3 .Or. nOpcao == 4 // Inclusão ou Alteração
        If !oRequest:HasProperty("codigo") .Or. Empty(oRequest["codigo"])
            cErro += "Campo 'codigo' obrigatório. "
        EndIf

        If !oRequest:HasProperty("loja") .Or. Empty(oRequest["loja"])
            cErro += "Campo 'loja' obrigatório. "
        EndIf

        If nOpcao == 3 // Inclusão
            If !oRequest:HasProperty("nome") .Or. Empty(oRequest["nome"])
                cErro += "Campo 'nome' obrigatório. "
            EndIf

            If !oRequest:HasProperty("nreduz") .Or. Empty(oRequest["nreduz"])
                cErro += "Campo 'nreduz' obrigatório. "
            EndIf
        EndIf
    EndIf

Return cErro

/*------------------------------------------------------------------------//
// Montar array para MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD MontarArrayCRMA980(oRequest, nOpcao) CLASS ClienteMsExecService
    Local aCliente := {}

    // Campos obrigatórios
    aAdd(aCliente, {"A1_COD",    oRequest["codigo"], Nil})
    aAdd(aCliente, {"A1_LOJA",   oRequest["loja"],   Nil})
    
    If nOpcao == 3 // Inclusão
        aAdd(aCliente, {"A1_NOME",   oRequest["nome"],   Nil})
        aAdd(aCliente, {"A1_NREDUZ", oRequest["nreduz"], Nil})
    EndIf

    // Campos opcionais
    If oRequest:HasProperty("nome") .And. !Empty(oRequest["nome"])
        aAdd(aCliente, {"A1_NOME", oRequest["nome"], Nil})
    EndIf

    If oRequest:HasProperty("nreduz") .And. !Empty(oRequest["nreduz"])
        aAdd(aCliente, {"A1_NREDUZ", oRequest["nreduz"], Nil})
    EndIf

    If oRequest:HasProperty("tipo") .And. !Empty(oRequest["tipo"])
        aAdd(aCliente, {"A1_TIPO", oRequest["tipo"], Nil})
    EndIf

    If oRequest:HasProperty("cgc") .And. !Empty(oRequest["cgc"])
        aAdd(aCliente, {"A1_CGC", oRequest["cgc"], Nil})
    EndIf

    If oRequest:HasProperty("endereco") .And. !Empty(oRequest["endereco"])
        aAdd(aCliente, {"A1_END", oRequest["endereco"], Nil})
    EndIf

    If oRequest:HasProperty("bairro") .And. !Empty(oRequest["bairro"])
        aAdd(aCliente, {"A1_BAIRRO", oRequest["bairro"], Nil})
    EndIf

    If oRequest:HasProperty("cidade") .And. !Empty(oRequest["cidade"])
        aAdd(aCliente, {"A1_MUN", oRequest["cidade"], Nil})
    EndIf

    If oRequest:HasProperty("estado") .And. !Empty(oRequest["estado"])
        aAdd(aCliente, {"A1_EST", oRequest["estado"], Nil})
    EndIf

    If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
        aAdd(aCliente, {"A1_CEP", oRequest["cep"], Nil})
    EndIf

    ConOut("[SERVICE][MONTAR] Array CRMA980 com " + cValToChar(Len(aCliente)) + " campos")

Return aCliente
