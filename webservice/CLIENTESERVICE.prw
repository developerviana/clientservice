#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  CLIENTESERVICE
//Autor:     Victor
//Descricao: Service para opera��es de cliente
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
/** Verifica se o usu�rio pode realizar determinada a��o sobre os Clientes
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
		ConOut("[PERMISSAO] Permiss�o n�o definida para " + cOrigem + "/" + cAcao)
	EndIf

Return lPode

/*------------------------------------------------------------------------//
// Buscar endere�o por CEP via API ViaCEP
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
            oResult["mensagem"] := "CEP n�o encontrado"
            FWRestArea(aArea)
            Return oResult
        EndIf

        oJson:FromJson(cResp)

        If oJson:HasProperty("erro") .And. oJson["erro"] == .T.
            ConOut("[ViaCEP][ERRO] CEP inv�lido: " + cCEP)
            oResult["erro"] := .T.
            oResult["mensagem"] := "CEP n�o encontrado na base de dados"
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
        ConOut("[ViaCEP][ERRO] Falha na comunica��o com o servi�o para CEP: " + cCEP)
        oResult["erro"] := .T.
        oResult["mensagem"] := "Erro na comunica��o com servi�o de CEP"
    EndIf

    FWRestArea(aArea)
Return oResult

/*------------------------------------------------------------------------//
// Validar dados do request
//------------------------------------------------------------------------*/
METHOD ValidarDados(oRequest, nOpcao) CLASS ClienteMsExecService
    Local cErro := ""
    
    // Valida��es b�sicas
    If nOpcao == 4  // Altera��o
        If !oRequest:HasProperty("codigo") .Or. Empty(oRequest["codigo"])
            cErro := "Campo 'codigo' � obrigat�rio"
        ElseIf !oRequest:HasProperty("loja") .Or. Empty(oRequest["loja"])
            cErro := "Campo 'loja' � obrigat�rio"
        EndIf
    EndIf
    
    // Valida��o de CEP se informado
    If Empty(cErro) .And. oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
        If Len(AllTrim(oRequest["cep"])) != 8
            cErro := "CEP deve conter 8 d�gitos"
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
        
        // Aqui voc� pode implementar sua l�gica de valida��o de token
        // Por exemplo: consultar uma tabela de tokens, validar JWT, etc.
        
        If Empty(cToken)
            ConOut("[TOKEN] Token vazio")
            Return Nil
        EndIf
        
        // Implementa��o simplificada - adapte conforme sua necessidade
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
            
            ConOut("[TOKEN] Token v�lido para usu�rio ADMIN")
        Else
            // Aqui voc� pode implementar outras valida��es
            // Como consultar tabela de usu�rios, validar JWT, etc.
            ConOut("[TOKEN] Token inv�lido: " + cToken)
            Return Nil
        EndIf
        
    RECOVER USING oError
        ConOut("[TOKEN][ERRO] " + oError:Description)
        Return Nil
    END SEQUENCE

Return oToken

/********************************************************************************************************/
/** Verifica campos obrigat�rios no JSON
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
			xRet["mensagem"] := "Campo obrigat�rio ausente: " + cCampo
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
			ConOut("[WSCLIENTE][VALIDA] Campo n�o encontrado na tabela: " + cNomeTabela)
			Loop
		EndIf

		cTipo     := aCampos[nIdx][2]
		nTamanho  := aCampos[nIdx][3]
		nDecimais := aCampos[nIdx][4]

		// Valida��o de tipo
		Do Case
			Case cTipo == "C" .And. ValType(xValorJson) != "C"
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser caractere."
				Exit

			Case cTipo == "N" .And. ValType(xValorJson) != "N" .And. !IsNumeric(xValorJson)
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser num�rico."
				Exit

			Case cTipo == "D" .And. !Empty(xValorJson) .And. !IsDate(xValorJson)
				xRet["erro"] := .T.
				xRet["mensagem"] := "Campo " + cCampoJson + " deveria ser data."
				Exit
		EndCase

		If cTipo == "C" .And. Len(AllTrim(xValorJson)) > nTamanho
			xRet["erro"] := .T.
			xRet["mensagem"] := "Campo " + cCampoJson + " excede o tamanho m�ximo de " + AllTrim(Str(nTamanho)) + " caracteres."
			Exit
		EndIf
	Next

Return xRet
