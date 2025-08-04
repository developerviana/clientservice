#include "totvs.ch"
#include "restful.ch"
#include "FWMVCDEF.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#include 'TOPCONN.CH'
#INCLUDE "TBICONN.CH"

/*------------------------------------------------------------------------//
//Programa:  WSCLIENTE
//Autor:     Victor 
//Descricao: Web Service REST simples para cadastro de clientes.
//------------------------------------------------------------------------*/

WsRestful WSCLIENTE Description "API REST para clientes" Format APPLICATION_JSON	

	WsData TOKEN As Character
	WsData FILIAL As Character
	WsData codigo as Character
	WsData loja as Character
	WsData cep as Character

	WSMETHOD POST INCLUIRCLIENTE ; 
		DESCRIPTION "Incluir cliente" ;
		PATH "/clientes" ;
		WSSYNTAX "clientes";
	
	WSMETHOD GET LISTARCLIENTES ; 
		DESCRIPTION "Listar todos os clientes" ;
		PATH "/clientes" ;
		WSSYNTAX "clientes";

	WSMETHOD PUT ALTERARCLIENTE ; 
		DESCRIPTION "Alterar cliente" ;
		PATH "/{codigo}/{loja}" ;
		WSSYNTAX "{codigo}/{loja}";

	WSMETHOD DELETE EXCLUIRCLIENTE ; 
		DESCRIPTION "Excluir cliente" ;
		PATH "/{codigo}/{loja}";
		WSSYNTAX "{codigo}/{loja}";

End WsRestful

/*******************************************************************************/
/** POST: Incluir cliente 
/*******************************************************************************/
WSMETHOD POST INCLUIRCLIENTE WSSERVICE WSCLIENTE
	Local lRet           := .T.
	Local cBody          := ::GetContent()
	Local jsonBody       := JsonObject():New()
	Local xResponse      := JsonObject():New()
	Local jsonToken      := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil)
	Local cFilParam      := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local aMapCampos     := {}

		aMapCampos := { ;
		{"A1_COD",      "codigo"}, ;
		{"A1_LOJA",     "loja"}, ;
		{"A1_NOME",     "nome"}, ;
		{"A1_NREDUZ",   "nomeReduzido"}, ;
		{"A1_END",      "endereco"}, ;
		{"A1_BAIRRO",   "bairro"}, ;
		{"A1_TIPO",     "tipo"}, ;
		{"A1_EST",      "estado"}, ;
		{"A1_COD_MUN",  "cod_ibge"}, ;
		{"A1_MUN",      "cidade"}, ;
		{"A1_CEP",      "cep"}, ;
		{"A1_INSCR",    "inscricaoEstadual"}, ;
		{"A1_CGC",      "cpfCnpj"}, ;
		{"A1_PAIS",     "pais"}, ;
		{"A1_EMAIL",    "email"}, ;
		{"A1_DDD",      "ddd"}, ;
		{"A1_TEL",      "telefone"}, ;
		{"A1_PESSOA",   "tipoPessoa"} }

	ConOut("[WSCLIENTE][POST] Iniciando inclusão de cliente")
	ConOut("[WSCLIENTE][POST] Body recebido: " + cBody)

	Begin Sequence
		jsonBody:FromJson(cBody)
		ConOut("[WSCLIENTE][POST] JSON parseado com sucesso")
	Recover
		ConOut("[WSCLIENTE][POST] Erro ao fazer parse do JSON")
		SetRestFault(400, "JSON inválido")
		Return .F.
	End Sequence

	If jsonToken <> Nil
		If !fPermissoes(jsonToken, "CLIENTE", "incluir")
			SetRestFault(403, "O usuário não tem permissão de incluir cliente.")
			Return .F.
		EndIf

		If Empty(cFilParam)
			SetRestFault(400, "Deve ser informada a filial.")
			Return .F.
		EndIf
	EndIf

	ConOut("[WSCLIENTE][POST] Chamando ExecutaMsCliente")
	xResponse := ExecutaMsCliente(jsonBody, 3, aMapCampos) 
	ConOut("[WSCLIENTE][POST] ExecutaMsCliente finalizado")

	If xResponse["erro"]
		ConOut("[WSCLIENTE][POST] Erro: " + xResponse["mensagem"])
		SetRestFault(400, xResponse["mensagem"])
		lRet := .F.
	Else
		ConOut("[WSCLIENTE][POST] Sucesso: " + xResponse["mensagem"])
		::SetResponse(xResponse:ToJson())
		lRet := .T.
	EndIf

	::SetContentType("application/json; charset=utf-8")
Return lRet


/*******************************************************************************/
/** GET: Listar clientes
/*******************************************************************************/
WSMETHOD GET LISTARCLIENTES WSSERVICE WSCLIENTE
	Local lRet        := .T.
	Local xResponse   := JsonObject():New()
	Local aClientes   := {}
	Local jsonCliente := Nil
	Local cQuery      := ""
	Local lAchou      := .F.

	cQuery := "SELECT A1_COD, A1_NOME, A1_LOJA, A1_MUN, A1_END, A1_BAIRRO, A1_EST, A1_CEP "
	cQuery += "FROM " + RetSqlName("SA1") + " "
	cQuery += "WHERE D_E_L_E_T_ = ' ' "
	cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "
	cQuery += "ORDER BY A1_COD, A1_LOJA"

	Begin Sequence
		TCQuery cQuery New Alias "QUERY_CLIENTES"

		If !QUERY_CLIENTES->(EOF())
			lAchou := .T.

			While !QUERY_CLIENTES->(EOF())
				jsonCliente := JsonObject():New()

				jsonCliente["codigo"]   := AllTrim(QUERY_CLIENTES->A1_COD)
				jsonCliente["loja"]     := AllTrim(QUERY_CLIENTES->A1_LOJA)
				jsonCliente["nome"]     := AllTrim(QUERY_CLIENTES->A1_NOME)
				jsonCliente["endereco"] := AllTrim(QUERY_CLIENTES->A1_END)
				jsonCliente["bairro"]   := AllTrim(QUERY_CLIENTES->A1_BAIRRO)
				jsonCliente["estado"]   := AllTrim(QUERY_CLIENTES->A1_EST)
				jsonCliente["cep"]      := AllTrim(QUERY_CLIENTES->A1_CEP)
				jsonCliente["municipio"]:= AllTrim(QUERY_CLIENTES->A1_MUN)

				AAdd(aClientes, jsonCliente)
				QUERY_CLIENTES->(DbSkip())
			EndDo
		EndIf

		QUERY_CLIENTES->(DbCloseArea())
	Recover
		lAchou := .F.
		ConOut("[WSCLIENTE] Erro ao acessar a tabela.")
	End Sequence

	If lAchou
		xResponse["sucesso"]  := .T.
		xResponse["erro"]     := .F.
		xResponse["dados"]    := aClientes
		xResponse["total"]    := Len(aClientes)
		xResponse["mensagem"] := "Clientes listados com sucesso"
	Else
		xResponse["sucesso"]  := .F.
		xResponse["erro"]     := .T.
		xResponse["dados"]    := {}
		xResponse["total"]    := 0
		xResponse["mensagem"] := "Não foi possível listar clientes."
	EndIf

	::SetResponse(xResponse:ToJson())
	::SetContentType("application/json; charset=utf-8")

Return lRet

/*******************************************************************************/
/** PUT: Alterar cliente 
/*******************************************************************************/
WSMETHOD PUT ALTERARCLIENTE WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local cBody
	Local jsonBody := JsonObject():New()
	Local jsonToken := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil) 
	Local cFilParam := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local cCodigo := ::aURLParms[1]
	Local cLoja := ::aURLParms[2]
	Local xResponse := JsonObject():New()
	Local oConsultaCEP   := Nil
	Local aMapCampos  := {}

	aMapCampos := { ;
		{"A1_END",      "endereco"}, ;
		{"A1_BAIRRO",   "bairro"}, ;
		{"A1_EST",      "estado"}, ;
		{"A1_MUN",      "cidade"}, ;
		{"A1_CEP",      "cep"} }

	cBody := ::GetContent()
	jsonBody:fromJson(cBody)

	jsonBody["codigo"] := cCodigo
	jsonBody["loja"] := cLoja

	oConsultaCEP := ConsultaCEP(jsonBody["cep"])

	If jsonToken <> NIL
		If !fPermissoes(jsonToken, "CLIENTE", "alterar")
			SetRestFault(403, "O usuário não tem permissão de alterar cliente.")	
			Return .F.
		EndIf

		If Empty(cFilParam)
			SetRestFault(400, "Deve ser informada a Filial!")
			Return .F.
		EndIf
	EndIf
	
	If oConsultaCEP != Nil
    
		If !jsonBody:HasProperty("endereco") .OR. Empty(jsonBody["endereco"])
			jsonBody["endereco"] := oConsultaCEP["logradouro"]
		EndIf

		If !jsonBody:HasProperty("bairro") .OR. Empty(jsonBody["bairro"])
			jsonBody["bairro"] := oConsultaCEP["bairro"]
		EndIf
		
		If !jsonBody:HasProperty("cidade") .OR. Empty(jsonBody["cidade"])
			jsonBody["cidade"] := oConsultaCEP["localidade"] 
		EndIf
		
		If !jsonBody:HasProperty("estado") .OR. Empty(jsonBody["estado"])
			jsonBody["estado"] := oConsultaCEP["uf"]
		EndIf

		If !jsonBody:HasProperty("cep") .OR. Empty(jsonBody["cep"])
			jsonBody["cep"] := oConsultaCEP["cep"]
		EndIf
		
	EndIf

	xResponse := ExecutaMsCliente(jsonBody, 4, aMapCampos) 

	If xResponse["erro"]
		SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
		lRet := .F.
	Else
		::SetResponse(xResponse:ToJson())
		lRet := .T.
	EndIf

	::SetContentType("application/json; charset=utf-8")
Return lRet

/*******************************************************************************/
/** DELETE: Excluir cliente
/*******************************************************************************/
WSMETHOD DELETE EXCLUIRCLIENTE WSSERVICE WSCLIENTE
	Local lRet        := .T.
	Local cBody       := ::GetContent()
	Local jsonBody    := JsonObject():New()
	Local xResponse   := JsonObject():New()
	Local jsonToken   := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil)
	Local nOpcAuto    := 5 
	Local aMapCampos := {}

	aMapCampos  := { ;
		{"A1_COD",    "codigo"}, ;
		{"A1_LOJA",   "loja"}, ;
	}
	jsonBody:FromJson(cBody)

	If jsonToken <> Nil
		If fPermissoes(jsonToken, "CLIENTE")
			xResponse := ExecutaMsCliente(jsonBody, nOpcAuto, aMapCampos)
			If !xResponse["erro"]
				::SetResponse(xResponse:ToJson())
			Else
				SetRestFault(400, xResponse["mensagem"])
				lRet := .F.
			EndIf
		Else
			SetRestFault(403, "Usuário sem permissão para excluir cliente.")
			lRet := .F.
		EndIf
	Else
		xResponse := ExecutaMsCliente(jsonBody, nOpcAuto, aMapCampos)
		If !xResponse["erro"]
			::SetResponse(xResponse:ToJson())
		Else
			SetRestFault(400, xResponse["mensagem"])
			lRet := .F.
		EndIf
	EndIf

	::SetContentType("application/json; charset=utf-8")
Return lRet

/********************************************************************************************************/
/** Verifica se o usuário pode realizar determinada ação sobre os Clientes
/********************************************************************************************************/
Static Function fPermissoes(jsonToken, cOrigem, cAcao)
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


/********************************************************************************************************/
/** Função para obter token web (simplificada)
/********************************************************************************************************/
Static Function GetWebToken(cToken)
	Local oToken := JsonObject():New()
	
	// Implementação simplificada
	oToken["USUARIO"] := "ADMIN"
	oToken["FILIAL"] := "01"
	
Return oToken


/********************************************************************************************************/
/** Função para deletar cliente
/********************************************************************************************************/
Static Function ExcluirCliente(jsonBody)
	Local aAreaAnt := FWGetArea()
	Local xRet := JsonObject():New()
	Local aSA1 := {}
	Local nOpcAuto := 5 
	Local lOk := .T.
	Local aCamposObrig := {"codigo", "loja", "nome", "nomeReduzido", "tipoPessoa", "cpfCnpj", "endereco", "cidade", "estado"}
	Local xValida

	Private lMsErroAuto := .F.
	xValida := fValidaCamposObrig(jsonBody, aCamposObrig)
	ConOut("[CLIENTE][EXCLUIR] Iniciando exclusão via JSON para " + jsonBody["codigo"] + "-" + jsonBody["loja"])

	xRet["erro"] := .F.
	xRet["mensagem"] := "Cliente excluído com sucesso"
	xRet["codigo"] := jsonBody["codigo"]
	xRet["loja"] := jsonBody["loja"]


	If xValida["erro"]
		xRet["erro"] := .T.
		xRet["mensagem"] := xValida["mensagem"]
		ConOut("[CLIENTE][ERRO] " + xValida["mensagem"])
		Return xRet
	EndIf

	AAdd(aSA1, {"A1_COD"    , PadR(jsonBody["codigo"], TamSX3("A1_COD")[1]), Nil})
	AAdd(aSA1, {"A1_LOJA"   , PadR(jsonBody["loja"], TamSX3("A1_LOJA")[1]), Nil})
	AAdd(aSA1, {"A1_FILIAL" , xFilial("SA1"), Nil})
	AAdd(aSA1, {"A1_NOME"   , jsonBody["nome"], Nil})
	AAdd(aSA1, {"A1_NREDUZ" , jsonBody["nomeReduzido"], Nil})
	AAdd(aSA1, {"A1_PESSOA" , jsonBody["tipoPessoa"], Nil})
	AAdd(aSA1, {"A1_CGC"    , jsonBody["cpfCnpj"], Nil})
	AAdd(aSA1, {"A1_INSCR"  , IIf(Haskey(jsonBody, "inscricaoEstadual"), jsonBody["inscricaoEstadual"], ""), Nil})
	AAdd(aSA1, {"A1_END"    , jsonBody["endereco"], Nil})
	AAdd(aSA1, {"A1_BAIRRO" , IIf(Haskey(jsonBody, "bairro"), jsonBody["bairro"], ""), Nil})
	AAdd(aSA1, {"A1_MUN"    , jsonBody["cidade"], Nil})
	AAdd(aSA1, {"A1_EST"    , jsonBody["estado"], Nil})
	AAdd(aSA1, {"A1_CEP"    , IIf(Haskey(jsonBody, "cep"), jsonBody["cep"], ""), Nil})
	AAdd(aSA1, {"A1_PAIS"   , IIf(Haskey(jsonBody, "pais"), jsonBody["pais"], "1058"), Nil})
	AAdd(aSA1, {"D_E_L_E_T_", " ", Nil})

	ConOut("[CLIENTE][EXCLUIR] Executando MsExecAuto com operação 5")
	lOk := MsExecAuto({|a, b, c| CRMA980(a, b, c)}, aSA1, nOpcAuto)

	If !lOk .Or. lMsErroAuto
		xRet["erro"] := .T.
		xRet["mensagem"] := "Erro ao excluir cliente via MsExecAuto."
		ConOut("[CLIENTE][ERRO] " + xRet["mensagem"])
	Else
		ConOut("[CLIENTE][SUCESSO] Cliente " + jsonBody["codigo"] + "-" + jsonBody["loja"] + " excluído com sucesso")
	EndIf

	RestArea(aAreaAnt)
Return xRet

/********************************************************************************************************/
/** Verifica campos obrigatórios no JSON
/********************************************************************************************************/
Static Function fValidaCamposObrig(jsonBody, aCampos)
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
/** Função para executar operações de cliente (incluir, alterar, excluir)
/********************************************************************************************************/
Static Function ExecutaMsCliente(jsonBody, nOpcAuto, aMapCampos)
	Local aSA1Auto     := {}
	Local aAI0Auto     := {}
	Local xRet         := JsonObject():New()
	Local xValor       := Nil
	Local nI           := 0
	Local cCampoTabela := ""
	Local cCampoJson   := ""

	Private lMsErroAuto := .F.

	xRet["erro"]    := .F.
	xRet["sucesso"] := .T.
	xRet["codigo"]  := jsonBody["codigo"]
	xRet["loja"]    := jsonBody["loja"]

    If nOpcAuto == 3  // INCLUSÃO

        ConOut("Teste de Inclusao")
        ConOut("Inicio: " + Time())

        // Preenche array SA1
        For nI := 1 To Len(aMapCampos)
            cCampoTabela := aMapCampos[nI][1]
            cCampoJson   := aMapCampos[nI][2]

            xValor := IIf(jsonBody:HasProperty(cCampoJson), jsonBody[cCampoJson], "")
            AAdd(aSA1Auto, {cCampoTabela, xValor, Nil})
        Next

        ConOut("Passou pelo Array da SA1")

        // Complemento AI0
        If jsonBody:HasProperty("saldo")
            AAdd(aAI0Auto, {"AI0_SALDO", jsonBody["saldo"], Nil})
            ConOut("Passou pelo Array da AI0")
        EndIf

        ConOut("Iniciando a gravacao")
        MsExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpcAuto, aAI0Auto)

        If lMsErroAuto
            xRet["erro"] := .T.
            xRet["sucesso"] := .F.
            xRet["mensagem"] := MostraErro()[6]
            MostraErro()
        Else
            ConOut("Cliente incluído com sucesso!")
            xRet["mensagem"] := "Cliente incluído com sucesso"
        EndIf

        ConOut("Fim: " + Time())

    ElseIf nOpcAuto == 4  // ALTERAÇÃO

        ConOut("Teste de Alteracao")
        ConOut("Inicio: " + Time())

        // Preenche array SA1
        For nI := 1 To Len(aMapCampos)
            cCampoTabela := aMapCampos[nI][1]
            cCampoJson   := aMapCampos[nI][2]

            xValor := IIf(jsonBody:HasProperty(cCampoJson), jsonBody[cCampoJson], "")
            AAdd(aSA1Auto, {cCampoTabela, xValor, Nil})
        Next

		If jsonBody:HasProperty("saldo")
            AAdd(aAI0Auto, {"AI0_SALDO", 30, Nil})
        ConOut("Passou pelo Array da AI0")

        ConOut("Iniciando a alteracao")
        MsExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpcAuto, aAI0Auto)

        If lMsErroAuto
            xRet["erro"] := .T.
            xRet["sucesso"] := .F.
            xRet["mensagem"] := MostraErro()[6]
            MostraErro()
        Else
            ConOut("Cliente alterado com sucesso!")
            xRet["mensagem"] := "Cliente alterado com sucesso"
        EndIf

        ConOut("Fim: " + Time())

	ElseIf nOpcAuto == 5  // EXCLUSÃO

		ConOut("Teste de Exclusao")
		ConOut("Inicio: " + Time())

		AAdd(aSA1Auto, {"A1_COD" , jsonBody["codigo"], Nil})
		AAdd(aSA1Auto, {"A1_LOJA", jsonBody["loja"], Nil})
		ConOut("Passou pelo Array da SA1")

		ConOut("Iniciando a exclusao")
		MsExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpcAuto, aAI0Auto)

		If lMsErroAuto
			xRet["erro"] := .T.
			xRet["sucesso"] := .F.
			xRet["mensagem"] := MostraErro()[6]
			MostraErro()
		Else
			ConOut("Cliente excluído com sucesso!")
			xRet["mensagem"] := "Cliente excluído com sucesso"
		EndIf

		ConOut("Fim: " + Time())

	EndIf

EndIf

Return xRet



/********************************************************************************************************/
/** Valida campos do JSON de acordo com a estrutura da tabela SA1
/********************************************************************************************************/
Static Function ValidaCamposJson(jsonBody, aMapCampos) 
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

/********************************************************************************************************/
/** Consulta CEP via ViaCEP
/********************************************************************************************************/
Static Function ConsultaCEP(cCEP)
    Local aArea        := FWGetArea()
    Local aHeader      := {}
    Local oRestClient  := FWRest():New("https://viacep.com.br/ws")
    Local oJson        := JsonObject():New()
    Local oResult      := Nil
    Local cMensagem    := ""
    Local cResp        := ""


    aAdd(aHeader, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')')
    aAdd(aHeader, 'Content-Type: application/json; charset=utf-8')

    oRestClient:SetPath("/" + cCEP + "/json/")

    If oRestClient:Get(aHeader)
        cResp := oRestClient:GetResult()

        If Empty(cResp)
            ConOut("[ViaCEP][ERRO] Resposta vazia para CEP: " + cCEP)
            FWRestArea(aArea)
            Return Nil
        EndIf

        oJson:FromJson(cResp)

        If oJson:GetJsonObject("erro") == "true"
            cMensagem := "O CEP informado no cadastro de cliente não consta na base de dados da consulta pública."
            ConOut("[ViaCEP][ERRO] " + cMensagem + " CEP: " + cCEP)
            FWRestArea(aArea)
            Return Nil
        EndIf
    Else
        ConOut("[ViaCEP][ERRO] Falha na comunicação com o serviço para CEP: " + cCEP)
        FWRestArea(aArea)
        Return Nil
    EndIf

    oResult := oJson

    FWRestArea(aArea)
Return oResult
