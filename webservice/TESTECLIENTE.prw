#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

/*------------------------------------------------------------------------//
// Teste específico de INSERT
//------------------------------------------------------------------------*/
User Function TESTINSERT()
    Local oService := ClienteMsExecService():New()
    Local oRequest := JsonObject():New()
    Local oResponse := Nil
    Local cCodigo := "TST" + StrZero(Randomize(1,999), 3)

    ConOut("[TESTINSERT] ========== TESTE DE INCLUSAO ==========")
    ConOut("[TESTINSERT] Codigo gerado: " + cCodigo)

    oRequest["codigo"]             := cCodigo
    oRequest["loja"]               := "01"
    oRequest["nome"]               := "CLIENTE TESTE INCLUSAO " + Time()
    oRequest["nomeReduzido"]       := "TESTE INC"
    oRequest["tipoPessoa"]         := "J"
    oRequest["tipo"]               := "F"
    oRequest["endereco"]           := "RUA TESTE INCLUSAO, 123"
    oRequest["bairro"]             := "CENTRO"
    oRequest["estado"]             := "SP"
    oRequest["cidade"]             := "SAO PAULO"
    oRequest["codigoIbge"]         := "35040"
    oRequest["cep"]                := "01310100"
    oRequest["inscricaoEstadual"]  := "123456789"
    oRequest["cpfCnpj"]            := "12345678000195"
    oRequest["pais"]               := "105"
    oRequest["email"]              := "teste@inclusao.com.br"
    oRequest["ddd"]                := "11"
    oRequest["telefone"]           := "99887766"

    ConOut("[TESTINSERT] JSON montado:")
    ConOut("[TESTINSERT] " + oRequest:ToJson())

    // Executa inclusão sem token (já logado no Protheus)
    oResponse := oService:IncluirClienteService(oRequest, "", "")
    
    ConOut("[TESTINSERT] ========== RESULTADO ==========")
    ConOut("[TESTINSERT] " + oResponse:ToJson())
    
    If !oResponse["erro"]
        ConOut("[TESTINSERT] SUCESSO: Cliente incluido com codigo " + cCodigo)
    Else
        ConOut("[TESTINSERT] ERRO: " + oResponse["mensagem"])
    EndIf

Return

/*------------------------------------------------------------------------//
// Teste específico de UPDATE/ALTER
//------------------------------------------------------------------------*/
User Function TESTUPDATE()
    Local oService := ClienteMsExecService():New()
    Local oRequest := JsonObject():New()
    Local oResponse := Nil
    Local cCodigo := "TST001"
    Local cLoja := "01"

    ConOut("[TESTUPDATE] ========== TESTE DE ALTERACAO ==========")
    ConOut("[TESTUPDATE] Alterando cliente: " + cCodigo + "-" + cLoja)

    // Verifica se cliente existe antes de alterar
    SA1->(DbSetOrder(1))
    If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
        ConOut("[TESTUPDATE] ERRO: Cliente nao encontrado. Execute TESTINSERT primeiro!")
        Return
    EndIf

    // Monta JSON para alteração
    oRequest["codigo"]       := cCodigo
    oRequest["loja"]         := cLoja
    oRequest["nome"]         := "CLIENTE TESTE ALTERADO " + Time()
    oRequest["nomeReduzido"] := "TESTE ALT"
    oRequest["endereco"]     := "RUA ALTERADA, 999"
    oRequest["bairro"]       := "NOVO BAIRRO"
    oRequest["email"]        := "alterado@teste.com.br"
    oRequest["telefone"]     := "11223344"
    oRequest["cep"]          := "04038001"

    ConOut("[TESTUPDATE] JSON para alteracao:")
    ConOut("[TESTUPDATE] " + oRequest:ToJson())

    // Executa alteração
    oResponse := oService:AlterarClienteService(oRequest)
    
    ConOut("[TESTUPDATE] ========== RESULTADO ==========")
    ConOut("[TESTUPDATE] " + oResponse:ToJson())
    
    If !oResponse["erro"]
        ConOut("[TESTUPDATE] SUCESSO: Cliente alterado com sucesso!")
    Else
        ConOut("[TESTUPDATE] ERRO: " + oResponse["mensagem"])
    EndIf

Return

/*------------------------------------------------------------------------//
// Teste específico de DELETE
//------------------------------------------------------------------------*/
User Function TESTDELETE()
    Local oService := ClienteMsExecService():New()
    Local oResponse := Nil
    Local cCodigo := "TST001"
    Local cLoja := "01"

    ConOut("[TESTDELETE] ========== TESTE DE EXCLUSAO ==========")
    ConOut("[TESTDELETE] Excluindo cliente: " + cCodigo + "-" + cLoja)

    // Verifica se cliente existe antes de excluir
    SA1->(DbSetOrder(1))
    If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
        ConOut("[TESTDELETE] ERRO: Cliente nao encontrado para exclusao!")
        ConOut("[TESTDELETE] Execute TESTINSERT primeiro para criar um cliente de teste.")
        Return
    EndIf

    ConOut("[TESTDELETE] Cliente encontrado:")
    ConOut("[TESTDELETE] Nome: " + SA1->A1_NOME)
    ConOut("[TESTDELETE] Nome Reduz: " + SA1->A1_NREDUZ)

    // Executa exclusão
    oResponse := oService:ExcluirClienteService(cCodigo, cLoja)
    
    ConOut("[TESTDELETE] ========== RESULTADO ==========")
    ConOut("[TESTDELETE] " + oResponse:ToJson())
    
    If !oResponse["erro"]
        ConOut("[TESTDELETE] SUCESSO: Cliente excluido com sucesso!")
        
        // Verifica se realmente foi excluído
        SA1->(DbSetOrder(1))
        If !SA1->(DbSeek(xFilial("SA1") + cCodigo + cLoja))
            ConOut("[TESTDELETE] CONFIRMADO: Cliente nao existe mais na base!")
        Else
            ConOut("[TESTDELETE] ATENCAO: Cliente ainda existe na base!")
        EndIf
    Else
        ConOut("[TESTDELETE] ERRO: " + oResponse["mensagem"])
    EndIf

Return

/*------------------------------------------------------------------------//
// Teste de listagem de clientes
//------------------------------------------------------------------------*/
User Function TESTLIST()
    Local oService := ClienteMsExecService():New()
    Local oResponse := Nil

    ConOut("[TESTLIST] ========== TESTE DE LISTAGEM ==========")

    oResponse := oService:ListarClientesService("", "")
    
    ConOut("[TESTLIST] ========== RESULTADO ==========")
    
    If !oResponse["erro"]
        ConOut("[TESTLIST] SUCESSO: " + cValToChar(oResponse["total"]) + " clientes encontrados")
        ConOut("[TESTLIST] Response completo: " + oResponse:ToJson())
    Else
        ConOut("[TESTLIST] ERRO: " + oResponse["mensagem"])
    EndIf

Return
