#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
//Programa:  TESTECLIENTE
//Autor:     Victor
//Descricao: Teste simples para validar API de clientes via MsExecAuto
//------------------------------------------------------------------------*/

User Function TESTECLI()
    Local oService := Nil
    Local oRequest := Nil
    Local oResponse := Nil

    ConOut("[TESTE] ========== INICIANDO TESTES CRMA980 ==========")

    // Instanciar service
    oService := ClienteMsExecService():New()

    // TESTE 1: Incluir cliente
    ConOut("[TESTE] 1. Testando inclus�o de cliente via CRMA980...")
    oRequest := JsonObject():New()
    oRequest["codigo"] := "TST001"
    oRequest["loja"]   := "01"
    oRequest["nome"]   := "Cliente Teste CRMA980"
    oRequest["nreduz"] := "Teste CRMA980"
    oRequest["tipo"]   := "F"
    oRequest["cgc"]    := "12345678901"
    oRequest["cep"]    := "01310-100" // Av. Paulista
    
    oResponse := oService:IncluirCliente(oRequest)
    ConOut("[TESTE] Resultado inclus�o: " + oResponse:ToJson())

    If !oResponse["erro"]
        // TESTE 2: Atualizar endere�o via CEP
        ConOut("[TESTE] 2. Testando atualiza��o de endere�o via CEP...")
        oResponse := oService:AtualizarEnderecoCEP("TST001", "01", "04038-001") // Vila Ol�mpia
        ConOut("[TESTE] Resultado atualiza��o CEP: " + oResponse:ToJson())

        // TESTE 3: Alterar cliente
        ConOut("[TESTE] 3. Testando altera��o de cliente...")
        oRequest["nome"] := "Cliente Teste Alterado CRMA980"
        oRequest["nreduz"] := "Teste Alt CRMA980"

        oResponse := oService:AlterarCliente(oRequest)
        ConOut("[TESTE] Resultado altera��o: " + oResponse:ToJson())

        // TESTE 4: Excluir cliente
        ConOut("[TESTE] 4. Testando exclus�o de cliente...")
        oResponse := oService:ExcluirCliente("TST001", "01")
        ConOut("[TESTE] Resultado exclus�o: " + oResponse:ToJson())
    EndIf

    // TESTE 5: Teste ViaCEP
    ConOut("[TESTE] 5. Testando integra��o ViaCEP...")
    oResponse := oService:BuscarEnderecoCEP("01310-100")
    ConOut("[TESTE] Resultado ViaCEP: " + oResponse:ToJson())

    ConOut("[TESTE] ========== TESTES FINALIZADOS ==========")

Return

/*------------------------------------------------------------------------//
// Teste espec�fico para inclus�o
//------------------------------------------------------------------------*/
User Function TESTINC()
    Local oService := ClienteMsExecService():New()
    Local oRequest := JsonObject():New()
    Local oResponse := Nil

    ConOut("[TESTE INC] Testando apenas inclus�o...")

    oRequest["codigo"] := "TST" + StrZero(Randomize(1, 999), 3)
    oRequest["loja"]   := "01"
    oRequest["nome"]   := "Cliente de Teste " + Time()
    oRequest["nreduz"] := "Teste " + Right(Time(), 5)
    oRequest["tipo"]   := "F"
    
    oResponse := oService:IncluirCliente(oRequest)
    ConOut("[TESTE INC] Resultado: " + oResponse:ToJson())

Return

/*------------------------------------------------------------------------//
// Teste para validar JSON de entrada
//------------------------------------------------------------------------*/
User Function TESTJSON()
    Local cJson := ""
    Local oRequest := JsonObject():New()

    ConOut("[TESTE JSON] Testando parsing JSON...")

    // JSON v�lido
    cJson := '{"codigo":"TST999","loja":"01","nome":"Teste JSON","nreduz":"JSON Test"}'
    ConOut("[TESTE JSON] JSON de entrada: " + cJson)

    Try
        oRequest:FromJson(cJson)
        ConOut("[TESTE JSON] Parse OK - C�digo: " + oRequest["codigo"])
        ConOut("[TESTE JSON] Parse OK - Nome: " + oRequest["nome"])
    Catch oError
        ConOut("[TESTE JSON] Erro no parse: " + oError:Description)
    End

Return

/*------------------------------------------------------------------------//
// Fun��o para simular chamada REST
//------------------------------------------------------------------------*/
User Function TESTREST()
    Local cJson := ""
    Local oRequest := JsonObject():New()
    Local oService := ClienteMsExecService():New()
    Local oResponse := Nil

    ConOut("[TESTE REST] Simulando chamada REST...")

    // Simular POST /clientes
    cJson := '{"codigo":"REST01","loja":"01","nome":"Cliente REST","nreduz":"REST","end":"Rua REST, 123"}'
    
    oRequest:FromJson(cJson)
    oResponse := oService:IncluirCliente(oRequest)
    
    ConOut("[TESTE REST] Status: " + IIF(oResponse["erro"], "400/500", "201"))
    ConOut("[TESTE REST] Response: " + oResponse:ToJson())

Return
