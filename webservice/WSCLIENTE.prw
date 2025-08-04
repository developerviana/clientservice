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

	WSMETHOD GET BUSCARCLIENTE ; 
		DESCRIPTION "Buscar cliente específico" ;
		PATH "/clientes/{codigo}/{loja}" ;
		WSSYNTAX "clientes/{codigo}/{loja}";	

	WSMETHOD PUT ALTERARCLIENTE ; 
		DESCRIPTION "Alterar cliente" ;
		PATH "/clientes/{codigo}/{loja}" ;
		WSSYNTAX "clientes/{codigo}/{loja}";

	WSMETHOD DELETE EXCLUIRCLIENTE ; 
		DESCRIPTION "Excluir cliente" ;
		PATH "/clientes/{codigo}/{loja}";
		WSSYNTAX "clientes/{codigo}/{loja}";

	WSMETHOD PUT ATUALIZARCEP ; 
		DESCRIPTION "Atualizar endereço por CEP" ;
		PATH "/clientes/{codigo}/{loja}/cep/{cep}" ;
		WSSYNTAX "clientes/{codigo}/{loja}/cep/{cep}";

	WSMETHOD POST IMPORTARCLIENTESCSV ; 
		DESCRIPTION "Importar clientes via arquivo CSV" ;
		PATH "/clientes/importar" ;
		WSSYNTAX "clientes/importar";

End WsRestful

/*******************************************************************************/
/** POST: Incluir cliente 
/*******************************************************************************/
WSMETHOD POST INCLUIRCLIENTE WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local cBody
	Local jsonBody := JsonObject():New()
	Local jsonToken := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil) 
	Local cFilParam := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local xResponse := JsonObject():New()
	Local oClienteService := Nil

	// Recupera o body da requisição
	cBody := ::GetContent()
	jsonBody:fromJson(cBody)

	if jsonToken <> NIL
		If fPermissoes(jsonToken, "CLIENTE")
			if cFilParam <> Nil
				oClienteService := ClienteMsExecService():New()
				xResponse := oClienteService:IncluirCliente(jsonBody)
				if (!xResponse["erro"])
					::SetResponse(xResponse:ToJson())
					lRet := .T.
				else
					SetRestFault(400, xResponse["mensagem"])
					lRet := .F.
				endif
			else
				SetRestFault(400, "Deve ser informado a Filial!")
				lRet := .F.	
			endif		
		else
			SetRestFault(403, "O usuário não tem permissão de incluir cliente.")	
			lRet := .F.		
		endif
	else
		// Permite operação sem token para testes
		oClienteService := ClienteMsExecService():New()
		xResponse := oClienteService:IncluirCliente(jsonBody)
		if (!xResponse["erro"])
			::SetResponse(xResponse:ToJson())
			lRet := .T.
		else
			SetRestFault(400, xResponse["mensagem"])
			lRet := .F.
		endif
	endif

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

	cQuery := "SELECT A1_COD, A1_LOJA, A1_END, A1_BAIRRO, A1_EST, A1_CEP "
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
				jsonCliente["endereco"] := AllTrim(QUERY_CLIENTES->A1_END)
				jsonCliente["bairro"]   := AllTrim(QUERY_CLIENTES->A1_BAIRRO)
				jsonCliente["estado"]   := AllTrim(QUERY_CLIENTES->A1_EST)
				jsonCliente["cep"]      := AllTrim(QUERY_CLIENTES->A1_CEP)

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
/** GET: Buscar cliente específico
/*******************************************************************************/
WSMETHOD GET BUSCARCLIENTE WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local xResponse := JsonObject():New()
	Local jsonToken
	Local jsonBody := JsonObject():New()
	Local cToken := Self:TOKEN
	Local cCodigo := ::aURLParms[1]
	Local cLoja := ::aURLParms[2]
    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local jsonCliente := JsonObject():New()
	
    If cToken <> Nil
		jsonToken := GetWebToken(cToken)
	else
		jsonToken := Nil 
	endif

	jsonBody["codigo"] := cCodigo
	jsonBody["loja"] := cLoja
	jsonBody["FILIAL"] := Self:FILIAL

	// Query para buscar cliente específico na SA1
	cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_NREDUZ, A1_PESSOA, A1_CGC, "
	cQuery += "A1_END, A1_NR_END, A1_COMPLEM, A1_BAIRRO, A1_MUN, A1_EST, A1_CEP, "
	cQuery += "A1_DDD, A1_TEL, A1_EMAIL, A1_MSBLQL "
	cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
	cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
	cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "
	cQuery += "AND A1_COD = '" + cCodigo + "' "
	cQuery += "AND A1_LOJA = '" + cLoja + "' "

	cQuery := ChangeQuery(cQuery)
	
	DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
	
	If (cAlias)->(!EOF())
		jsonCliente["codigo"] := AllTrim((cAlias)->A1_COD)
		jsonCliente["loja"] := AllTrim((cAlias)->A1_LOJA)
		jsonCliente["nome"] := AllTrim((cAlias)->A1_NOME)
		jsonCliente["nomeReduzido"] := AllTrim((cAlias)->A1_NREDUZ)
		jsonCliente["tipo"] := AllTrim((cAlias)->A1_PESSOA)
		jsonCliente["cnpjCpf"] := AllTrim((cAlias)->A1_CGC)
		jsonCliente["endereco"] := AllTrim((cAlias)->A1_END)
		jsonCliente["numero"] := AllTrim((cAlias)->A1_NR_END)
		jsonCliente["complemento"] := AllTrim((cAlias)->A1_COMPLEM)
		jsonCliente["bairro"] := AllTrim((cAlias)->A1_BAIRRO)
		jsonCliente["cidade"] := AllTrim((cAlias)->A1_MUN)
		jsonCliente["estado"] := AllTrim((cAlias)->A1_EST)
		jsonCliente["cep"] := AllTrim((cAlias)->A1_CEP)
		jsonCliente["telefone"] := AllTrim((cAlias)->A1_DDD) + AllTrim((cAlias)->A1_TEL)
		jsonCliente["email"] := AllTrim((cAlias)->A1_EMAIL)
		jsonCliente["ativo"] := IIF((cAlias)->A1_MSBLQL == "1", .F., .T.)
		
		xResponse["sucesso"] := .T.
		xResponse["erro"] := .F.
		xResponse["dados"] := jsonCliente
		xResponse["mensagem"] := "Cliente encontrado"
	Else
		xResponse["sucesso"] := .F.
		xResponse["erro"] := .T.
		xResponse["codigo"] := "404"
		xResponse["mensagem"] := "Cliente não encontrado"
	EndIf
	
	(cAlias)->(DbCloseArea())

	If !xResponse["erro"]
		::SetResponse(xResponse:ToJson())
	Else
		SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])	
		lRet := .F.
	EndIf

	::SetContentType("application/json; charset=utf-8")

Return lRet

/*******************************************************************************/
/** PUT: Alterar cliente via CRMA980
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
	Local oClienteService := Nil

	// Recupera o body da requisição
	cBody := ::GetContent()
	jsonBody:fromJson(cBody)
	
	// Adiciona código e loja da URL
	jsonBody["codigo"] := cCodigo
	jsonBody["loja"] := cLoja

	if jsonToken <> NIL
		If fPermissoes(jsonToken, "CLIENTE")
			if cFilParam <> Nil
				oClienteService := ClienteMsExecService():New()
				xResponse := oClienteService:AlterarCliente(jsonBody)
				if (!xResponse["erro"])
					::SetResponse(xResponse:ToJson())
					lRet := .T.
				else
					SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
					lRet := .F.
				endif
			else
				SetRestFault(400, "Deve ser informado a Filial!")
				lRet := .F.	
			endif		
		else
			SetRestFault(403, "O usuário não tem permissão de alterar cliente.")	
			lRet := .F.		
		endif
	else
		// Permite operação sem token para testes
		oClienteService := ClienteMsExecService():New()
		xResponse := oClienteService:AlterarCliente(jsonBody)
		if (!xResponse["erro"])
			::SetResponse(xResponse:ToJson())
			lRet := .T.
		else
			SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
			lRet := .F.
		endif
	endif

	::SetContentType("application/json; charset=utf-8")

Return lRet

/*******************************************************************************/
/** DELETE: Excluir cliente via CRMA980
/*******************************************************************************/
WSMETHOD DELETE EXCLUIRCLIENTE WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local jsonToken := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil) 
	Local cFilParam := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local cCodigo := ::aURLParms[1]
	Local cLoja := ::aURLParms[2]
	Local xResponse := JsonObject():New()
    Local oClienteService := Nil

	if jsonToken <> NIL
		If fPermissoes(jsonToken, "CLIENTE")
			if cFilParam <> Nil
				oClienteService := ClienteMsExecService():New()
				xResponse := oClienteService:ExcluirCliente(cCodigo, cLoja)
				if (!xResponse["erro"])
					::SetResponse(xResponse:ToJson())
					lRet := .T.
				else
					SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
					lRet := .F.
				endif
			else
				SetRestFault(400, "Deve ser informado a Filial!")
				lRet := .F.	
			endif		
		else
			SetRestFault(403, "O usuário não tem permissão de excluir cliente.")	
			lRet := .F.		
		endif
	else
		// Permite operação sem token para testes
		oClienteService := ClienteMsExecService():New()
		xResponse := oClienteService:ExcluirCliente(cCodigo, cLoja)
		if (!xResponse["erro"])
			::SetResponse(xResponse:ToJson())
			lRet := .T.
		else
			SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
			lRet := .F.
		endif
	endif

	::SetContentType("application/json; charset=utf-8")

Return lRet

/*******************************************************************************/
/** PUT: Atualizar endereço por CEP
/*******************************************************************************/
WSMETHOD PUT ATUALIZARCEP WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local jsonToken := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil) 
	Local cFilParam := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local cCodigo := ::aURLParms[1]
	Local cLoja := ::aURLParms[2]
	Local cCEP := ::aURLParms[3]
	Local xResponse := JsonObject():New()
    Local oClienteService

	if jsonToken <> NIL
		If fPermissoes(jsonToken, "CLIENTE")
			if cFilParam <> Nil
				oClienteService := ClienteMsExecService():New()
				xResponse := oClienteService:AtualizarEnderecoCEP(cCodigo, cLoja, cCEP)
				if (!xResponse["erro"])
					::SetResponse(xResponse:ToJson())
					lRet := .T.
				else
					SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
					lRet := .F.
				endif
			else
				SetRestFault(400, "Deve ser informado a Filial!")
				lRet := .F.	
			endif		
		else
			SetRestFault(403, "O usuário não tem permissão de alterar endereço.")	
			lRet := .F.		
		endif
	else
		// Permite operação sem token para testes
		oClienteService := ClienteMsExecService():New()
		xResponse := oClienteService:AtualizarEnderecoCEP(cCodigo, cLoja, cCEP)
		if (!xResponse["erro"])
			::SetResponse(xResponse:ToJson())
			lRet := .T.
		else
			SetRestFault(IIF(xResponse["codigo"] == "404", 404, 400), xResponse["mensagem"])
			lRet := .F.
		endif
	endif

	::SetContentType("application/json; charset=utf-8")

Return lRet

/*******************************************************************************/
/** POST: Importar clientes via CSV
/*******************************************************************************/
WSMETHOD POST IMPORTARCLIENTESCSV WSSERVICE WSCLIENTE
	Local lRet := .T.
	Local cBody
	Local jsonBody := JsonObject():New()
	Local jsonToken := IIf(Self:TOKEN <> Nil, GetWebToken(Self:TOKEN), Nil) 
	Local cFilParam := IIf(Self:FILIAL <> Nil, Self:FILIAL, "01")
	Local xResponse := JsonObject():New()
	Local oClienteService := Nil

	// Recupera o body da requisição
	cBody := ::GetContent()
	jsonBody:fromJson(cBody)

	if jsonToken <> NIL
		If fPermissoes(jsonToken, "CLIENTE")
			if cFilParam <> Nil
				xResponse := oClienteService:ImportarClientesCSV(jsonBody)
				if (!xResponse["erro"])
					::SetResponse(xResponse:ToJson())
					lRet := .T.
				else
					SetRestFault(400, xResponse["mensagem"])
					lRet := .F.
				endif
			else
				SetRestFault(400, "Deve ser informado a Filial!")
				lRet := .F.	
			endif		
		else
			SetRestFault(403, "O usuário não tem permissão de importar clientes.")	
			lRet := .F.		
		endif
	else
		// Permite operação sem token para testes
		oClienteService := ClienteMsExecService():New()
		xResponse := oClienteService:ImportarClientesCSV(jsonBody)
		if (!xResponse["erro"])
			::SetResponse(xResponse:ToJson())
			lRet := .T.
		else
			SetRestFault(400, xResponse["mensagem"])
			lRet := .F.
		endif
	endif

	::SetContentType("application/json; charset=utf-8")

Return lRet

/********************************************************************************************************/
/** Verifica se o usuário pode realizar determinada ação sobre os Clientes
/********************************************************************************************************/
Static Function fPermissoes(jsonToken, cOrigem)
	Local lxPode := .T.
	
	// Implementar validação de permissões conforme necessário
	// Por enquanto permite todas as operações
	
	if (cOrigem == "CLIENTE")
		lxPode := .T. // Permitir por enquanto
	endif

Return lxPode

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
/** Função para converter query string em JSON (simplificada)
/********************************************************************************************************/
Static Function QueryStringToJson(aQueryString)
	Local oJson := JsonObject():New()
	Local nI
	
	If Len(aQueryString) > 0
		For nI := 1 To Len(aQueryString)
			// Implementar parse da query string
		Next
	EndIf
	
Return oJson

