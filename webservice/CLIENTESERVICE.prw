#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  CLIENTESERVICE
//Autor:     Victor
//Descricao: Service para opera��es de cliente via MsExecAuto CRMA980
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
    Local aCliente := {}
    Local cErro := ""
    Local oEndereco := Nil
    Local oError

    ConOut("[SERVICE][INCLUIR] Iniciando inclus�o via CRMA980")

    BEGIN SEQUENCE

        // Valida��o de dados obrigat�rios
        cErro := Self:ValidarDados(oRequest, 3)
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            BREAK
        EndIf

        // Verifica se cliente j� existe
        SA1->(DbSetOrder(1))
        If SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Cliente j� existe: " + oRequest["codigo"] + "-" + oRequest["loja"]
            BREAK
        EndIf

        // Busca dados do endere�o via CEP
        If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
            oEndereco := Self:BuscarEnderecoCEP(oRequest["cep"])
            If !oEndereco["erro"]
                oRequest["endereco"] := oEndereco["logradouro"]
                oRequest["bairro"]   := oEndereco["bairro"]
                oRequest["cidade"]   := oEndereco["localidade"]
                oRequest["estado"]   := oEndereco["uf"]
            EndIf
        EndIf

        // Montar dados para o CRMA980
        aCliente := Self:MontarArrayCRMA980(oRequest, 3)
        ConOut("[SERVICE][INCLUIR] Array CRMA980 com " + cValToChar(Len(aCliente)) + " campos")

        // Executa inclus�o via MsExecAuto
        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 3)

        If lMsErroAuto
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro no MsExecAuto CRMA980"
        Else
            ConOut("[SERVICE][INCLUIR] Cliente inclu�do com sucesso: " + oRequest["codigo"] + "-" + oRequest["loja"])
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente inclu�do com sucesso"
            oResponse["codigo"] := oRequest["codigo"]
            oResponse["loja"] := oRequest["loja"]
            oResponse["nome"] := oRequest["nome"]
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][INCLUIR][EXCEPTION] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    END SEQUENCE

Return oResponse

/*------------------------------------------------------------------------//
// Alterar cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD AlterarCliente(oRequest) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente  := {}
    Local cErro     := ""
    Local oEndereco := Nil
    Local oError    := Nil

    ConOut("[SERVICE][ALTERAR] Iniciando altera��o via CRMA980")

    BEGIN SEQUENCE

        // Valida��o dos dados
        cErro := Self:ValidarDados(oRequest, 4)
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            BREAK
        EndIf

        // Verifica��o da exist�ncia do cliente
        SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente n�o encontrado: " + oRequest["codigo"] + "-" + oRequest["loja"]
            BREAK
        EndIf

        // Enriquecer dados com endere�o via CEP, se informado
        If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
            oEndereco := Self:BuscarEnderecoCEP(oRequest["cep"])
            If !oEndereco["erro"]
                oRequest["endereco"] := oEndereco["logradouro"]
                oRequest["bairro"]   := oEndereco["bairro"]
                oRequest["cidade"]   := oEndereco["localidade"]
                oRequest["estado"]   := oEndereco["uf"]
            EndIf
        EndIf

        // Monta dados para envio ao CRMA980
        aCliente := Self:MontarArrayCRMA980(oRequest, 4)
        ConOut("[SERVICE][ALTERAR] Array CRMA980 montado com " + cValToChar(Len(aCliente)) + " campos")

        // Executa altera��o via MsExecAuto
        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 4)

        If lMsErroAuto
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro no MsExecAuto CRMA980"
        Else
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente alterado com sucesso via CRMA980"
            oResponse["codigo"] := oRequest["codigo"]
            oResponse["loja"] := oRequest["loja"]
            oResponse["nome"] := oRequest["nome"]
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][ALTERAR][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    END SEQUENCE

Return oResponse


/*------------------------------------------------------------------------//
// Excluir cliente via MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD ExcluirCliente(cCodigo, cLoja) CLASS ClienteMsExecService
    Local oResponse := Nil
    Local aCliente  := {}
    Local cErro     := ""
    Local oError    := Nil

    oResponse := JsonObject():New()
    ConOut("[SERVICE][EXCLUIR] Iniciando exclus�o via CRMA980")
    
    BEGIN SEQUENCE

        // Valida��o b�sica
        If Empty(cCodigo) .Or. Empty(cLoja)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "C�digo e Loja obrigat�rios"
            BREAK
        EndIf

        // Verificar se cliente existe
        SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente n�o encontrado: " + cCodigo + "-" + cLoja
            BREAK
        EndIf

        // Montar array b�sico para CRMA980
        aCliente := {{"A1_COD", cCodigo, Nil}}

        ConOut("[SERVICE][EXCLUIR] Array CRMA980 montado para exclus�o")

        // Chamar MsExecAuto
        MSExecAuto({|x, y| CRMA980(x, y)}, aCliente, 5)

        If lMsErroAuto
            cErro := "Erro no MsExecAuto CRMA980"
            ConOut("[SERVICE][EXCLUIR][ERRO] " + cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
        Else
            ConOut("[SERVICE][EXCLUIR] Sucesso: " + cCodigo + "-" + cLoja)
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente exclu�do com sucesso via CRMA980"
            oResponse["codigo"] := cCodigo
            oResponse["loja"] := cLoja
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][EXCLUIR][EXCEPTION] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    END SEQUENCE

Return oResponse

/*------------------------------------------------------------------------//
// Atualizar endere�o do cliente baseado no CEP
//------------------------------------------------------------------------*/
METHOD AtualizarEnderecoCEP(cCodigo, cLoja, cCEP) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local oEndereco := Nil
    Local oRequest  := JsonObject():New()
    Local oError    := Nil

    ConOut("[SERVICE][ATUALIZAR_CEP] Atualizando endere�o via CEP: " + cCEP)

    BEGIN SEQUENCE

        // Buscar dados do CEP
        oEndereco := Self:BuscarEnderecoCEP(cCEP)

        If oEndereco["erro"]
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro ao buscar CEP: " + oEndereco["mensagem"]
            BREAK
        EndIf

        // Montar objeto request para altera��o
        oRequest["codigo"]    := cCodigo
        oRequest["loja"]      := cLoja
        oRequest["cep"]       := cCEP
        oRequest["endereco"]  := oEndereco["logradouro"]
        oRequest["bairro"]    := oEndereco["bairro"]
        oRequest["cidade"]    := oEndereco["localidade"]
        oRequest["estado"]    := oEndereco["uf"]

        // Chama m�todo AlterarCliente com os novos dados
        oResponse := Self:AlterarCliente(oRequest)

        // Anexa dados adicionais ao sucesso
        If !oResponse["erro"]
            oResponse["endereco_atualizado"] := .T.
            oResponse["dados_cep"] := oEndereco
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][ATUALIZAR_CEP][EXCEPTION] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno ao atualizar endere�o via CEP: " + oError:Description
    END SEQUENCE

Return oResponse

/*------------------------------------------------------------------------//
// Buscar endere�o via ViaCEP
//------------------------------------------------------------------------*/
METHOD BuscarEnderecoCEP(cCEP) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local oRest     := Nil
    Local cUrl      := ""
    Local cJson     := ""
    Local oError    := Nil

    ConOut("[SERVICE][VIACEP] Buscando CEP: " + cCEP)

    BEGIN SEQUENCE

        // Limpar caracteres do CEP
        cCEP := StrTran(StrTran(cCEP, "-", ""), ".", "")

        If Len(cCEP) != 8
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "CEP deve ter 8 d�gitos"
            BREAK
        EndIf

        // Monta URL do servi�o ViaCEP
        cUrl := "https://viacep.com.br/ws/" + cCEP + "/json/"

        // Instancia REST client
        oRest := FWRest():New()
        oRest:SetPath(cUrl)

        // Realiza requisi��o
        If oRest:Get()
            cJson := oRest:GetResult()
            ConOut("[SERVICE][VIACEP] Resposta: " + cJson)

            oResponse:FromJson(cJson)

            // Verifica se o ViaCEP retornou erro
            If oResponse:HasProperty("erro") .And. oResponse["erro"]
                oResponse["erro"] := .T.
                oResponse["mensagem"] := "CEP n�o encontrado"
                BREAK
            EndIf

            // CEP encontrado com sucesso
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "CEP encontrado com sucesso"

        Else
            ConOut("[SERVICE][VIACEP][ERRO] Falha na requisi��o GET")
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro ao consultar ViaCEP: " + oRest:GetLastError()
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][VIACEP][EXCEPTION] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno ao consultar CEP: " + oError:Description
    END SEQUENCE

Return oResponse

/*------------------------------------------------------------------------//
// Validar dados obrigat�rios
//------------------------------------------------------------------------*/
METHOD ValidarDados(oRequest, nOpcao) CLASS ClienteMsExecService
    Local cErro := ""

    If nOpcao == 3 .Or. nOpcao == 4 // Inclus�o ou Altera��o
        If !oRequest:HasProperty("codigo") .Or. Empty(oRequest["codigo"])
            cErro += "Campo 'codigo' obrigat�rio. "
        EndIf

        If !oRequest:HasProperty("loja") .Or. Empty(oRequest["loja"])
            cErro += "Campo 'loja' obrigat�rio. "
        EndIf

        If nOpcao == 3 // Inclus�o
            If !oRequest:HasProperty("nome") .Or. Empty(oRequest["nome"])
                cErro += "Campo 'nome' obrigat�rio. "
            EndIf

            If !oRequest:HasProperty("nreduz") .Or. Empty(oRequest["nreduz"])
                cErro += "Campo 'nreduz' obrigat�rio. "
            EndIf
        EndIf
    EndIf

Return cErro

/*------------------------------------------------------------------------//
// Montar array para MsExecAuto CRMA980
//------------------------------------------------------------------------*/
METHOD MontarArrayCRMA980(oRequest, nOpcao) CLASS ClienteMsExecService
    Local aCliente := {}

    // Campos obrigat�rios
    aAdd(aCliente, {"A1_COD",    oRequest["codigo"], Nil})
    aAdd(aCliente, {"A1_LOJA",   oRequest["loja"],   Nil})
    
    If nOpcao == 3 // Inclus�o
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
