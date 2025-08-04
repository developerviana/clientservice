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


METHOD New() CLASS ClienteMsExecService
Return Self

/*------------------------------------------------------------------------//
// Incluir cliente 
//------------------------------------------------------------------------*/
METHOD IncluirCliente(oRequest) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente := {}
    Local cErro := ""
    Local oEndereco := Nil
    Local oError

    ConOut("[SERVICE][INCLUIR] Iniciando inclusão via CRMA980")

    BEGIN SEQUENCE

        cErro := Self:ValidarDados(oRequest, 3)
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            BREAK
        EndIf

        SA1->(DbSetOrder(1))
        If SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Cliente já existe: " + oRequest["codigo"] + "-" + oRequest["loja"]
            BREAK
        EndIf

        If oRequest:HasProperty("cep") .And. !Empty(oRequest["cep"])
            oEndereco := Self:BuscarEnderecoCEP(oRequest["cep"])
            If !oEndereco["erro"]
                oRequest["endereco"] := oEndereco["logradouro"]
                oRequest["bairro"]   := oEndereco["bairro"]
                oRequest["cidade"]   := oEndereco["localidade"]
                oRequest["estado"]   := oEndereco["uf"]
            EndIf
        EndIf

        aCliente := Self:MontarArrayCRMA980(oRequest, 3)
        ConOut("[SERVICE][INCLUIR] Array CRMA980 com " + cValToChar(Len(aCliente)) + " campos")

        MSExecAuto({|x,y| CRMA980(x,y)}, aCliente, 3)

        If lMsErroAuto
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Erro no MsExecAuto CRMA980"
        Else
            ConOut("[SERVICE][INCLUIR] Cliente incluído com sucesso: " + oRequest["codigo"] + "-" + oRequest["loja"])
            oResponse["erro"] := .F.
            oResponse["mensagem"] := "Cliente incluído com sucesso"
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
// Alterar cliente 
//------------------------------------------------------------------------*/
METHOD AlterarCliente(oRequest) CLASS ClienteMsExecService
    Local oResponse := JsonObject():New()
    Local aCliente  := {}
    Local cErro     := ""
    Local oEndereco := Nil
    Local oError    := Nil

    ConOut("[SERVICE][ALTERAR] Iniciando alteração via CRMA980")

    BEGIN SEQUENCE

        // Validação dos dados
        cErro := Self:ValidarDados(oRequest, 4)
        If !Empty(cErro)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := cErro
            BREAK
        EndIf

        // Verificação da existência do cliente
        SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + oRequest["codigo"] + oRequest["loja"]))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente não encontrado: " + oRequest["codigo"] + "-" + oRequest["loja"]
            BREAK
        EndIf

        // Enriquecer dados com endereço via CEP, se informado
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

        // Executa alteração via MsExecAuto
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
// Excluir cliente
//------------------------------------------------------------------------*/
METHOD ExcluirCliente(cCodigo, cLoja) CLASS ClienteMsExecService
    Local oResponse := Nil
    Local aCliente  := {}
    Local cErro     := ""
    Local oError    := Nil

    oResponse := JsonObject():New()
    ConOut("[SERVICE][EXCLUIR] Iniciando exclusão via CRMA980")
    
    BEGIN SEQUENCE

        // Validação básica
        If Empty(cCodigo) .Or. Empty(cLoja)
            oResponse["erro"] := .T.
            oResponse["mensagem"] := "Código e Loja obrigatórios"
            BREAK
        EndIf

        // Verificar se cliente existe
        SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA
        If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
            oResponse["erro"] := .T.
            oResponse["codigo"] := "404"
            oResponse["mensagem"] := "Cliente não encontrado: " + cCodigo + "-" + cLoja
            BREAK
        EndIf

        // Montar array básico para CRMA980
        aCliente := {{"A1_COD", cCodigo, Nil}}

        ConOut("[SERVICE][EXCLUIR] Array CRMA980 montado para exclusão")

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
            oResponse["mensagem"] := "Cliente excluído com sucesso via CRMA980"
            oResponse["codigo"] := cCodigo
            oResponse["loja"] := cLoja
        EndIf

    RECOVER USING oError
        ConOut("[SERVICE][EXCLUIR][EXCEPTION] " + oError:Description)
        oResponse["erro"] := .T.
        oResponse["mensagem"] := "Erro interno: " + oError:Description
    END SEQUENCE

Return oResponse
