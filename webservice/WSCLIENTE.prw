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
		PATH "/clientes" ;
		WSSYNTAX "clientes";
		
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
		{"A1_PESSOA",   "tipoPessoa"}, ;
		{"A1_TIPO",     "tipo"}, ;
		{"A1_END",      "endereco"}, ;
		{"A1_BAIRRO",   "bairro"}, ;
		{"A1_EST",      "estado"}, ;
		{"A1_MUN",      "cidade"}, ;
		{"A1_COD_MUN",  "codigoIbge"}, ;
		{"A1_CEP",      "cep"}, ;
		{"A1_INSCR",    "inscricaoEstadual"}, ;
		{"A1_CGC",      "cpfCnpj"}, ;
		{"A1_PAIS",     "pais"}, ;
		{"A1_EMAIL",    "email"}, ;
		{"A1_DDD",      "ddd"}, ;
		{"A1_TEL",      "telefone"} }

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
		If !ClienteMsExecService():fPermissoes(jsonToken, "CLIENTE", "incluir")
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

	ClienteMsExecService():BuscarEnderecoCEP(jsonBody["cep"])

	If jsonToken <> NIL
		If !ClienteMsExecService():fPermissoes(jsonToken, "CLIENTE", "alterar")
			SetRestFault(403, "O usuário não tem permissão de alterar cliente.")	
			Return .F.
		EndIf

		If Empty(cFilParam)
			SetRestFault(400, "Deve ser informada a Filial!")
			Return .F.
		EndIf
	EndIf

	ConOut("[WSCLIENTE][PUT] Chamando ExecutaMsCliente")

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
		If ClienteMsExecService():fPermissoes(jsonToken, "CLIENTE")
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
/** Função para executar operações de cliente (incluir, alterar, excluir)
/********************************************************************************************************/
Static Function ExecutaMsCliente(jsonBody, nOpcAuto, aMapCampos)
	Local aSA1Auto     := {}
	Local aAI0Auto     := {}
	Local xRet         := JsonObject():New()
    Local oModel    := Nil
    Local oSA1Mod   := Nil
    Local lDeuCerto := .F.
    Local aErro     := {}

	Private lMsErroAuto := .F.

	xRet["erro"]    := .F.
	xRet["sucesso"] := .T.
	xRet["codigo"]  := jsonBody["codigo"]
	xRet["loja"]    := jsonBody["loja"]

    If nOpcAuto == 3  // INCLUSÃO

		ConOut("Teste de Inclusao")
		ConOut("Inicio: " + Time())

		oModel := FWLoadModel("CRMA980") 
		oModel:SetOperation(3)
		oModel:Activate()

		oSA1Mod := oModel:getModel("SA1MASTER")
		
		oSA1Mod:setValue("A1_COD",       jsonBody["codigo"]        ) 
		oSA1Mod:setValue("A1_LOJA",      jsonBody["loja"]          ) 
		oSA1Mod:setValue("A1_NOME",      jsonBody["nome"]          )            
		oSA1Mod:setValue("A1_NREDUZ",    jsonBody["nomeReduzido"]  ) 
		oSA1Mod:setValue("A1_END",       jsonBody["endereco"]      ) 
		oSA1Mod:setValue("A1_BAIRRO",    jsonBody["bairro"]        ) 
		oSA1Mod:setValue("A1_TIPO",      jsonBody["tipo"]          ) 
		oSA1Mod:setValue("A1_EST",       jsonBody["estado"]        ) 
		oSA1Mod:setValue("A1_COD_MUN",   jsonBody["cod_ibge"]      )                
		oSA1Mod:setValue("A1_MUN",       jsonBody["cidade"]        ) 
		oSA1Mod:setValue("A1_CEP",       jsonBody["cep"]           ) 
		oSA1Mod:setValue("A1_INSCR",     jsonBody["inscricaoEstadual"]) 
		oSA1Mod:setValue("A1_CGC",       jsonBody["cpfCnpj"]       )           
		oSA1Mod:setValue("A1_PAIS",      jsonBody["pais"]          )       
		oSA1Mod:setValue("A1_EMAIL",     jsonBody["email"]         ) 
		oSA1Mod:setValue("A1_DDD",       jsonBody["ddd"]           )      
		oSA1Mod:setValue("A1_TEL",       jsonBody["telefone"]      )              
		oSA1Mod:setValue("A1_PESSOA",    jsonBody["tipoPessoa"]    ) 
    
		If oModel:VldData()

			If oModel:CommitData()
				lDeuCerto := .T.
				ConOut("[WSERVICE] Cliente incluído com sucesso!")
				xRet["mensagem"] := "[WSERVICE] Cliente incluído com sucesso"
			Else
				lDeuCerto := .F.
				ConOut("[WSERVICE] Erro no CommitData")
			EndIf
			
		Else
			lDeuCerto := .F.
			ConOut("[WSERVICE] Erro na validação dos dados")
		EndIf
		
		If !lDeuCerto
			aErro := oModel:GetErrorMessage()
			
			ConOut("[INCLUSAO][ERRO] Id do formulário de origem: " + AllToChar(aErro[01]))
			ConOut("[INCLUSAO][ERRO] Id do campo de origem: " + AllToChar(aErro[02]))
			ConOut("[INCLUSAO][ERRO] Id do formulário de erro: " + AllToChar(aErro[03]))
			ConOut("[INCLUSAO][ERRO] Id do campo de erro: " + AllToChar(aErro[04]))
			ConOut("[INCLUSAO][ERRO] Id do erro: " + AllToChar(aErro[05]))
			ConOut("[INCLUSAO][ERRO] Mensagem do erro: " + AllToChar(aErro[06]))
			ConOut("[INCLUSAO][ERRO] Mensagem da solução: " + AllToChar(aErro[07]))
			ConOut("[INCLUSAO][ERRO] Valor atribuído: " + AllToChar(aErro[08]))
			ConOut("[INCLUSAO][ERRO] Valor anterior: " + AllToChar(aErro[09]))
			
			xRet["erro"] := .T.
			xRet["sucesso"] := .F.
			xRet["mensagem"] := AllToChar(aErro[06])
		EndIf
		
		oModel:DeActivate()
		
		ConOut("Fim: " + Time())

    ElseIf nOpcAuto == 3  // ALTERAÇÃO

		ConOut("Teste de Inclusao")
		ConOut("Inicio: " + Time())

		oModel := FWLoadModel("CRMA980") 
		oModel:SetOperation(4)
		oModel:Activate()

		oSA1Mod := oModel:getModel("SA1MASTER")
		
		oSA1Mod:setValue("A1_COD",       jsonBody["codigo"]        ) 
		oSA1Mod:setValue("A1_LOJA",      jsonBody["loja"]          ) 
		oSA1Mod:setValue("A1_NOME",      jsonBody["nome"]          )        
		oSA1Mod:setValue("A1_NREDUZ",    jsonBody["nomeReduzido"]  ) 
		oSA1Mod:setValue("A1_END",       jsonBody["endereco"]      ) 
		oSA1Mod:setValue("A1_EST",       jsonBody["estado"]        ) 
		oSA1Mod:setValue("A1_MUN",       jsonBody["cidade"]        )
		oSA1Mod:setValue("A1_CEP",       jsonBody["cep"]           ) 
		oSA1Mod:setValue("A1_PAIS",      jsonBody["pais"]          ) 
		
		If oModel:VldData()

			If oModel:CommitData()
				lDeuCerto := .T.
				ConOut("[WSERVICE] Cliente incluído com sucesso!")
				xRet["mensagem"] := "[WSERVICE] Cliente incluído com sucesso"
				
			Else
				lDeuCerto := .F.
				ConOut("[WSERVICE] Erro no CommitData")
			EndIf
			
		Else
			lDeuCerto := .F.
			ConOut("[WSERVICE] Erro na validação dos dados")
		EndIf
		
		If !lDeuCerto
			aErro := oModel:GetErrorMessage()
			
			ConOut("[INCLUSAO][ERRO] Id do formulário de origem: " + AllToChar(aErro[01]))
			ConOut("[INCLUSAO][ERRO] Id do campo de origem: " + AllToChar(aErro[02]))
			ConOut("[INCLUSAO][ERRO] Id do formulário de erro: " + AllToChar(aErro[03]))
			ConOut("[INCLUSAO][ERRO] Id do campo de erro: " + AllToChar(aErro[04]))
			ConOut("[INCLUSAO][ERRO] Id do erro: " + AllToChar(aErro[05]))
			ConOut("[INCLUSAO][ERRO] Mensagem do erro: " + AllToChar(aErro[06]))
			ConOut("[INCLUSAO][ERRO] Mensagem da solução: " + AllToChar(aErro[07]))
			ConOut("[INCLUSAO][ERRO] Valor atribuído: " + AllToChar(aErro[08]))
			ConOut("[INCLUSAO][ERRO] Valor anterior: " + AllToChar(aErro[09]))
			
			xRet["erro"] := .T.
			xRet["sucesso"] := .F.
			xRet["mensagem"] := AllToChar(aErro[06])
		EndIf
		
		oModel:DeActivate()
		
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
			Return xRet
		Else
			ConOut("Cliente excluído com sucesso!")
			xRet["mensagem"] := "[WSERVICE]Cliente excluído com sucesso"
			xRet["codigo"]   := jsonBody["codigo"]
			Return xRet
		EndIf

		ConOut("Fim: " + Time())

	EndIf

Return xRet
