#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  WSCLIENTE
//Autor:     Victor 
//Descricao: Web Service REST simples para cadastro de clientes via MsExecAuto
//------------------------------------------------------------------------*/

WSRESTFUL ClienteMsExecAPI DESCRIPTION "API REST para clientes via MsExecAuto CRMA980"

    WSDATA codigo    AS STRING OPTIONAL
    WSDATA loja      AS STRING OPTIONAL
    WSDATA cep       AS STRING OPTIONAL

    WSMETHOD POST    DESCRIPTION "Incluir cliente"           WSSYNTAX "/clientes"                           PATH "/clientes"
    WSMETHOD PUT     DESCRIPTION "Alterar cliente"           WSSYNTAX "/clientes/{codigo}/{loja}"           PATH "/clientes" 
    WSMETHOD DELETE  DESCRIPTION "Excluir cliente"           WSSYNTAX "/clientes/{codigo}/{loja}"           PATH "/clientes"
    WSMETHOD PATCH   DESCRIPTION "Atualizar endereço por CEP" WSSYNTAX "/clientes/{codigo}/{loja}/cep/{cep}" PATH "/clientes"

END WSRESTFUL

/*------------------------------------------------------------------------//
// POST - Incluir cliente
//------------------------------------------------------------------------*/
WSMETHOD POST WSSERVICE ClienteMsExecAPI
    Local oResponse := JsonObject():New()
    Local oService  := ClienteMsExecService():New()
    Local oRequest  := JsonObject():New()
    Local cBody     := ::GetContent()

    ConOut("[WSCLIENTE][POST] Iniciando inclusão via MsExecAuto")

    Try
        If !Empty(cBody)
            oRequest:FromJson(cBody)
            ConOut("[WSCLIENTE][POST] JSON recebido: " + cBody)
        Else
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Body vazio"
            ::SetResponse(oResponse:ToJson())
            ::SetStatus(400)
            Return .F.
        EndIf

        oResponse := oService:IncluirCliente(oRequest)

        If oResponse["erro"]
            ::SetStatus(400)
        Else
            ::SetStatus(201)
        EndIf

        ::SetResponse(oResponse:ToJson())

    Catch oError
        ConOut("[WSCLIENTE][POST][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
        ::SetResponse(oResponse:ToJson())
        ::SetStatus(500)
    End

    ConOut("[WSCLIENTE][POST] Finalizado")

Return .T.

/*------------------------------------------------------------------------//
// PUT - Alterar cliente  
//------------------------------------------------------------------------*/
WSMETHOD PUT WSSERVICE ClienteMsExecAPI
    Local oResponse := JsonObject():New()
    Local oService  := ClienteMsExecService():New()
    Local oRequest  := JsonObject():New()
    Local cBody     := ::GetContent()

    ConOut("[WSCLIENTE][PUT] Iniciando alteração via MsExecAuto")
    ConOut("[WSCLIENTE][PUT] Cliente: " + Self:codigo + "-" + Self:loja)

    Try
        If Empty(Self:codigo) .Or. Empty(Self:loja)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Código e Loja obrigatórios na URL"
            ::SetResponse(oResponse:ToJson())
            ::SetStatus(400)
            Return .F.
        EndIf

        If !Empty(cBody)
            oRequest:FromJson(cBody)
            ConOut("[WSCLIENTE][PUT] JSON recebido: " + cBody)
        Else
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Body vazio"
            ::SetResponse(oResponse:ToJson())
            ::SetStatus(400)
            Return .F.
        EndIf

        oRequest["codigo"] := Self:codigo
        oRequest["loja"] := Self:loja

        oResponse := oService:AlterarCliente(oRequest)

        If oResponse["erro"]
            ::SetStatus(IIF(oResponse["codigo"] == "404", 404, 400))
        Else
            ::SetStatus(200)
        EndIf

        ::SetResponse(oResponse:ToJson())

    Catch oError
        ConOut("[WSCLIENTE][PUT][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
        ::SetResponse(oResponse:ToJson())
        ::SetStatus(500)
    End

    ConOut("[WSCLIENTE][PUT] Finalizado")

Return .T.

/*------------------------------------------------------------------------//
// DELETE - Excluir cliente
//------------------------------------------------------------------------*/
WSMETHOD DELETE WSSERVICE ClienteMsExecAPI
    Local oResponse := JsonObject():New()
    Local oService  := ClienteMsExecService():New()

    ConOut("[WSCLIENTE][DELETE] Iniciando exclusão via MsExecAuto")
    ConOut("[WSCLIENTE][DELETE] Cliente: " + Self:codigo + "-" + Self:loja)

    Try
        If Empty(Self:codigo) .Or. Empty(Self:loja)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Código e Loja obrigatórios na URL"
            ::SetResponse(oResponse:ToJson())
            ::SetStatus(400)
            Return .F.
        EndIf

        oResponse := oService:ExcluirCliente(Self:codigo, Self:loja)

        If oResponse["erro"]
            ::SetStatus(IIF(oResponse["codigo"] == "404", 404, 400))
        Else
            ::SetStatus(200)
        EndIf

        ::SetResponse(oResponse:ToJson())

    Catch oError
        ConOut("[WSCLIENTE][DELETE][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
        ::SetResponse(oResponse:ToJson())
        ::SetStatus(500)
    End

    ConOut("[WSCLIENTE][DELETE] Finalizado")

Return .T.

/*------------------------------------------------------------------------//
// PATCH - Atualizar endereço por CEP
//------------------------------------------------------------------------*/
WSMETHOD PATCH WSSERVICE ClienteMsExecAPI
    Local oResponse := JsonObject():New()
    Local oService  := ClienteMsExecService():New()

    ConOut("[WSCLIENTE][PATCH] Iniciando atualização de endereço via CEP")
    ConOut("[WSCLIENTE][PATCH] Cliente: " + Self:codigo + "-" + Self:loja + " CEP: " + Self:cep)

    Try
        If Empty(Self:codigo) .Or. Empty(Self:loja) .Or. Empty(Self:cep)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Código, Loja e CEP obrigatórios na URL"
            ::SetResponse(oResponse:ToJson())
            ::SetStatus(400)
            Return .F.
        EndIf

        oResponse := oService:AtualizarEnderecoCEP(Self:codigo, Self:loja, Self:cep)

        If oResponse["erro"]
            ::SetStatus(IIF(oResponse["codigo"] == "404", 404, 400))
        Else
            ::SetStatus(200)
        EndIf

        ::SetResponse(oResponse:ToJson())

    Catch oError
        ConOut("[WSCLIENTE][PATCH][ERRO] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
        ::SetResponse(oResponse:ToJson())
        ::SetStatus(500)
    End

    ConOut("[WSCLIENTE][PATCH] Finalizado")

Return .T.
