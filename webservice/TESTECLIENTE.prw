#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
// Programa:  TESTECLIENTE
// Autor:     Victor
// Descrição: Teste simples para validar API de clientes via MsExecAuto
//------------------------------------------------------------------------*/

User Function TESTECLI()
    Local oService := ClienteMsExecService():New()
    Local oRequest := JsonObject():New()
    Local oResponse := Nil

    ConOut("[TESTE] ========== INICIANDO TESTES CRMA980 ==========")

    // TESTE 1: Incluir cliente
    ConOut("[TESTE] 1. Incluir cliente via CRMA980...")
    oRequest["codigo"] := "TST001"
    oRequest["loja"]   := "01"
    oRequest["nome"]   := "Cliente Teste CRMA980"
    oRequest["nreduz"] := "Teste CRMA980"
    oRequest["tipo"]   := "F"
    oRequest["cgc"]    := "12345678901"
    oRequest["cep"]    := "01310-100" // Av. Paulista

    oResponse := oService:IncluirCliente(oRequest)
    ConOut("[TESTE] Resultado inclusão: " + oResponse:ToJson())

    If !oResponse["erro"]

        // TESTE 2: Atualizar endereço via CEP
        ConOut("[TESTE] 2. Atualizar endereço via CEP...")
        oResponse := oService:AtualizarEnderecoCEP("TST001", "01", "04038-001") // Vila Olímpia
        ConOut("[TESTE] Resultado atualização CEP: " + oResponse:ToJson())

        // TESTE 3: Alterar cliente
        ConOut("[TESTE] 3. Alterar cliente via CRMA980...")
        oRequest["nome"] := "Cliente Teste Alterado CRMA980"
        oRequest["nreduz"] := "Teste Alt CRMA980"

        oResponse := oService:AlterarCliente(oRequest)
        ConOut("[TESTE] Resultado alteração: " + oResponse:ToJson())

        // TESTE 4: Excluir cliente
        ConOut("[TESTE] 4. Excluir cliente...")
        oResponse := oService:ExcluirCliente("TST001", "01")
        ConOut("[TESTE] Resultado exclusão: " + oResponse:ToJson())

    EndIf

    // TESTE 5: Consulta ViaCEP isolado
    ConOut("[TESTE] 5. Teste de integração com ViaCEP...")
    oResponse := oService:BuscarEnderecoCEP("01310-100")
    ConOut("[TESTE] Resultado ViaCEP: " + oResponse:ToJson())

    ConOut("[TESTE] ========== TESTES FINALIZADOS ==========")

Return

/*------------------------------------------------------------------------//
// Teste específico de inclusão
//------------------------------------------------------------------------*/
User Function TESTINC()
    Local oService := ClienteMsExecService():New()
    Local oRequest := JsonObject():New()
    Local oResponse := Nil
    Local cCod := "TST" + StrZero(Randomize(1,999), 3)

    ConOut("[TESTINC] Iniciando teste de inclusão simples...")

    oRequest["codigo"] := cCod
    oRequest["loja"]   := "01"
    oRequest["nome"]   := "Cliente de Teste " + Time()
    oRequest["nreduz"] := "Teste " + Right(Time(), 5)
    oRequest["tipo"]   := "F"

    oResponse := oService:IncluirCliente(oRequest)
    ConOut("[TESTINC] Resultado inclusão: " + oResponse:ToJson())

Return

/*------------------------------------------------------------------------//
// Teste para validar parsing de JSON
//------------------------------------------------------------------------*/
User Function TESTJSON()
    Local cJson := '{"codigo":"TST999","loja":"01","nome":"Teste JSON","nreduz":"JSON Test"}'
    Local oRequest := JsonObject():New()
    Local oError := Nil

    ConOut("[TESTJSON] Testando parsing de JSON...")
    ConOut("[TESTJSON] JSON de entrada: " + cJson)

    BEGIN SEQUENCE
        oRequest:FromJson(cJson)
        ConOut("[TESTJSON] Parse OK - Código: " + oRequest["codigo"])
        ConOut("[TESTJSON] Parse OK - Nome: " + oRequest["nome"])
    RECOVER USING oError
        ConOut("[TESTJSON][ERRO] Falha no parsing: " + oError:Description)
    END SEQUENCE

Return

/*------------------------------------------------------------------------//
// Simulação de chamada REST
//------------------------------------------------------------------------*/
User Function TESTREST()
    Local cJson := '{"codigo":"REST01","loja":"01","nome":"Cliente REST","nreduz":"REST","end":"Rua REST, 123"}'
    Local oRequest := JsonObject():New()
    Local oService := ClienteMsExecService():New()
    Local oResponse := Nil

    ConOut("[TESTREST] Simulando chamada REST...")

    oRequest:FromJson(cJson)
    oResponse := oService:IncluirCliente(oRequest)

    ConOut("[TESTREST] Status HTTP: " + IIF(oResponse["erro"], "400/500", "201"))
    ConOut("[TESTREST] Response: " + oResponse:ToJson())

Return
