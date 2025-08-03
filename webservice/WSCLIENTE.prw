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
		DESCRIPTION "Alterar cliente via CRMA980" ;
		PATH "/clientes/{codigo}/{loja}" ;
		WSSYNTAX "clientes/{codigo}/{loja}";

	WSMETHOD DELETE EXCLUIRCLIENTE ; 
		DESCRIPTION "Excluir cliente via CRMA980" ;
		PATH "/clientes/{codigo}/{loja}";
		WSSYNTAX "clientes/{codigo}/{loja}";

	WSMETHOD PUT ATUALIZARCEP ; 
		DESCRIPTION "Atualizar endereço por CEP via ViaCEP" ;
		PATH "/clientes/{codigo}/{loja}/cep/{cep}" ;
		WSSYNTAX "clientes/{codigo}/{loja}/cep/{cep}";

	WSMETHOD POST IMPORTARCLIENTESCSV ; 
		DESCRIPTION "Importar clientes via arquivo CSV" ;
		PATH "/clientes/importar" ;
		WSSYNTAX "clientes/importar";

End WsRestful

/*******************************************************************************/
/** POST: Incluir cliente via CRMA980
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
	Local lRet := .T.
	Local xResponse := JsonObject():New()
	Local jsonToken
	Local jsonBody := JsonObject():New()
	Local cToken := Self:TOKEN
    Local oClienteService := Nil
    
	// Converte query string para JSON
	jsonBody := QueryStringToJson(Self:aQueryString)
	
	If cToken <> Nil
		jsonToken := GetWebToken(cToken)
	else
		jsonToken := Nil 
	endif
    
	jsonBody["FILIAL"] := Self:FILIAL

	oClienteService := ClienteMsExecService():New()
	xResponse := oClienteService:ListarClientes(jsonBody)

	If !xResponse["erro"]
		::SetResponse(xResponse:ToJson())
	Else
		SetRestFault(400, xResponse["mensagem"])	
		lRet := .F.
	EndIf

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
    Local oClienteService 
	
    If cToken <> Nil
		jsonToken := GetWebToken(cToken)
	else
		jsonToken := Nil 
	endif

	jsonBody["codigo"] := cCodigo
	jsonBody["loja"] := cLoja
	jsonBody["FILIAL"] := Self:FILIAL

	oClienteService := ClienteMsExecService():New()
	xResponse := oClienteService:BuscarCliente(cCodigo, cLoja)

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

