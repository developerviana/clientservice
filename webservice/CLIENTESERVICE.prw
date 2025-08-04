#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  CLIENTESERVICE
//Autor:     Victor
//Descricao: Service para operações de cliente
//------------------------------------------------------------------------*/

CLASS ClienteMsExecService
    METHOD New() CONSTRUCTOR

    METHOD BuscarEnderecoCEP(cCEP)
    METHOD ValidarDados(oRequest, nOpcao)
    METHOD GetWebTokenService(cToken)
    METHOD PermissoesClienteService(jsonToken, cOrigem, cAcao)
    METHOD fValidaCamposObrig(jsonBody, aCampos)
    METHOD ValidaCamposJson(jsonBody, aMapCampos)

ENDCLASS

METHOD New() CLASS ClienteMsExecService
Return Self


/********************************************************************************************************/
/** Verifica se o usuário pode realizar determinada ação sobre os Clientes
/********************************************************************************************************/
METHOD PermissoesClienteService(jsonToken, cOrigem, cAcao) CLASS ClienteMsExecService
	Local lPode := .F.

	If FWIsAdmin()
		Return .T.
	EndIf

	If jsonToken == Nil .Or. Empty(cOrigem) .Or. Empty(cAcao)
		Return .F.
	EndIf

	If jsonToken:Has("modulos") .And. jsonToken:GetJsonObject("modulos"):Has(cOrigem)
		lPode := jsonToken:GetJsonObject("modulos"):GetJsonObject(cOrigem):GetLogical(cAcao)
	Else
		ConOut("[PERMISSAO] Permissão não definida para " + cOrigem + "/" + cAcao)
	EndIf

Return lPode

/*------------------------------------------------------------------------//
// Buscar endereço por CEP via API ViaCEP
//------------------------------------------------------------------------*/
METHOD BuscarEnderecoCEP(cCEP) CLASS ClienteMsExecService
    Local aArea        := FWGetArea()
    Local aHeader      := {}
    Local oRestClient  := FWRest():New("https://viacep.com.br/ws")
    Local oJson        := JsonObject():New()
    Local oResult      := JsonObject():New()
    Local cResp        := ""

    oResult["erro"] := .F.
    oResult["mensagem"] := ""

    aAdd(aHeader, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')')
    aAdd(aHeader, 'Content-Type: application/json; charset=utf-8')

    oRestClient:SetPath("/" + cCEP + "/json/")

    If oRestClient:Get(aHeader)
        cResp := oRestClient:GetResult()

        If Empty(cResp)
            ConOut("[ViaCEP][ERRO] Resposta vazia para CEP: " + cCEP)
            oResult["erro"] := .T.
            oResult["mensagem"] := "CEP não encontrado"
            FWRestArea(aArea)
            Return oResult
        EndIf

        oJson:FromJson(cResp)

        If oJson:HasProperty("erro") .And. oJson["erro"] == .T.
            ConOut("[ViaCEP][ERRO] CEP inválido: " + cCEP)
            oResult["erro"] := .T.
            oResult["mensagem"] := "CEP não encontrado na base de dados"
            FWRestArea(aArea)
            Return oResult
        EndIf

        // Copia os dados do retorno
        oResult["cep"] := oJson["cep"]
        oResult["logradouro"] := oJson["logradouro"]
        oResult["bairro"] := oJson["bairro"]
        oResult["localidade"] := oJson["localidade"]
        oResult["uf"] := oJson["uf"]
        
    Else
        ConOut("[ViaCEP][ERRO] Falha na comunicação com o serviço para CEP: " + cCEP)
        oResult["erro"] := .T.
        oResult["mensagem"] := "Erro na comunicação com serviço de CEP"
    EndIf

    FWRestArea(aArea)
Return oResult

/*------------------------------------------------------------------------//
// Validar dados do request
//------------------------------------------------------------------------*/
METHOD ValidarDados(oRequest, nOpcao) CLASS ClienteMsExecService
    Local cErro := ""
    
    // Validações básicas
    If nOpcao == 4  // Alteração
        If !oRequest:HasProperty("codigo") .Or. Empty(oRequest["codigo"])
            cErro := "Campo 'codigo' é obrigatório"
        ElseIf !oRequest:HasProperty("loja") .Or. Empty(oRequest["loja"])
            cErro := "Campo 'loja' é obrigatório"
        EndIf
    EndIf
    
    // Validação de CEP se informado
    If Empty(cErro) .And. oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
        If Len(AllTrim(oRequest["cep"])) != 8
            cErro := "CEP deve conter 8 dígitos"
        EndIf
    EndIf

Return cErro

/*------------------------------------------------------------------------//
// Obter e validar token web
//------------------------------------------------------------------------*/
METHOD GetWebTokenService(cToken) CLASS ClienteMsExecService
    Local oToken := JsonObject():New()
    Local oError := Nil
    Local oModulos := JsonObject():New()
    Local oCliente := JsonObject():New()
    
    BEGIN SEQUENCE
        
        // Aqui você pode implementar sua lógica de validação de token
        // Por exemplo: consultar uma tabela de tokens, validar JWT, etc.
        
        If Empty(cToken)
            ConOut("[TOKEN] Token vazio")
            Return Nil
        EndIf
        
        // Implementação simplificada - adapte conforme sua necessidade
        If AllTrim(Upper(cToken)) == "ADMIN_TOKEN"
            oToken["USUARIO"] := "ADMIN"
            oToken["FILIAL"] := "01"
            oToken["VALIDO"] := .T.
            
            oCliente["incluir"] := .T.
            oCliente["alterar"] := .T.
            oCliente["excluir"] := .T.
            oCliente["consultar"] := .T.
            
            oModulos["CLIENTE"] := oCliente
            oToken["modulos"] := oModulos
            
            ConOut("[TOKEN] Token válido para usuário ADMIN")
        Else
            // Aqui você pode implementar outras validações
            // Como consultar tabela de usuários, validar JWT, etc.
            ConOut("[TOKEN] Token inválido: " + cToken)
            Return Nil
        EndIf
        
    RECOVER USING oError
        ConOut("[TOKEN][ERRO] " + oError:Description)
        Return Nil
    END SEQUENCE

Return oToken

/********************************************************************************************************/
/** Verifica campos obrigatórios no JSON
/********************************************************************************************************/
METHOD fValidaCamposObrig(jsonBody, aCampos) CLASS ClienteMsExecService
	Local xRet := JsonObject():New()
	Local nI := 0
	Local cCampo := ""

	xRet["erro"] := .F.
	xRet["mensagem"] := ""

	For nI := 1 To Len(aCampos)
		cCampo := aCampos[nI]
		If Empty(jsonBody[cCampo])
			xRet["erro"] := .T.
			xRet["mensagem"] := "Campo obrigatório ausente: " + cCampo
			xRet["campo"] := cCampo
			Exit
		EndIf
	Next

Return xRet

/********************************************************************************************************/
/** Valida campos do JSON de acordo com a estrutura da tabela SA1
/********************************************************************************************************/
METHOD ValidaCamposJson(jsonBody, aMapCampos) CLASS ClienteMsExecService
	Local aCampos     := {}
	Local cCampoJson  := ""
	Local xValorJson  := Nil
	Local cTipo       := ""
	Local nTamanho    := 0
	Local nDecimais   := 0
	Local xRet        := JsonObject():New()
	Local nIdx        := 0
	Local cNomeTabela := ""

	xRet["erro"]     := .F.
	xRet["mensagem"] := ""

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))
	aCampos := SA1->(DbStruct())

	For nI := 1 To Len(aMapCampos)
		aItem := aMapCampos[nI]
		cNomeTabela := aItem[1]
		cCampoJson  := aItem[2]
		xValorJson  := jsonBody[cCampoJson]
		nIdx := AScan(aCampos, {|x| x[1] == cNomeTabela})

		If nIdx <= 0
			ConOut("[WSCLIENTE][VALIDA] Campo não encontrado na tabela: " + cNomeTabela)
			Loop
		EndIf

		cTipo     := aCampos[nIdx][2]
		nTamanho  := aCampos[nIdx][3]
		nDecimais := aCampos[nIdx][4]

		// Validação de tipo
		Do Case
			Case cTipo == "C" .And. ValType(xValorJson) != "C"
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser caractere."
				Exit

			Case cTipo == "N" .And. ValType(xValorJson) != "N" .And. !IsNumeric(xValorJson)
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser numérico."
				Exit

			Case cTipo == "D" .And. !Empty(xValorJson) .And. !IsDate(xValorJson)
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser data."
				Exit
		EndCase

		If cTipo == "C" .And. Len(AllTrim(xValorJson)) > nTamanho
			xRet["erro"] := .T.
			xRet["mensagem"] := "Campo " + cCampoJson + " excede o tamanho máximo de " + AllTrim(Str(nTamanho)) + " caracteres."
			Exit
		EndIf
	Next

Return xRet
