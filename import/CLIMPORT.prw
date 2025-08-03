#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"

/*------------------------------------------------------------------------//
//Programa:  CLIMPORT
//Autor:     Victor 
//Descricao: Importação de Endereços de Clientes via CSV.
//------------------------------------------------------------------------*/

User Function CLIMPORT()
    Local cTexto
    Local bConfirm
    Local bSair
    Local oDialog
    Local oContainer

    Private cPlanilha := ""
    Private aOpcoes := {}
    Private cAbas := ""
    Private dDataIni := sToD("")
    Private dDataFin := sToD("")
    Private oTGet1
    Private oTGet2
    Private oTButton1

    Public cSuccessCount := 0
    Public lTableCleaned := .F.
    Public oExcel

    bConfirm := {|| FwMsgRun(,{|oSay| ImportaEndereco(cPlanilha), NIL}, 'Buscando Planilha ... ', "",) }
    bSair := {|| Iif(MsgYesNo('Você tem certeza que deseja sair da rotina?', 'Sair da rotina'), (oDialog:DeActivate()), NIL) }

    oDialog := FWDialogModal():New()

    oDialog:SetBackground(.T.)
    oDialog:SetTitle('Importação Endereços - Clientes')
    oDialog:SetSize(120, 200) 
    oDialog:EnableFormBar(.T.)
    oDialog:SetCloseButton(.F.)
    oDialog:SetEscClose(.F.)  
    oDialog:CreateDialog()
    oDialog:CreateFormBar()
    oDialog:AddButton('Importar', bConfirm, 'Confirmar', , .T., .F., .T.)
    oDialog:AddButton('Sair', bSair, 'Sair', , .T., .F., .T.)
    
    oContainer := TPanel():New( ,,, oDialog:getPanelMain() )
    oContainer:Align := CONTROL_ALIGN_ALLCLIENT

    cTexto := '• Selecione o CSV com os endereços dos clientes.'

    oSay2 := TSay():New(010,010,{||cTexto},oContainer,,,,,,.T.,,,800,20)

    oSay1 := TSay():New(035,010,{||'Arquivo CSV:'},oContainer,,,,,,.T.,,,100,9)
    oTGet0 := tGet():New(045,010,{|u| if(PCount()>0,cPlanilha:=u,cPlanilha)},oContainer ,180,9,"",,,,,,,.T.,,, {|| .T. } ,,,,.F.,,,"cPlanilha")

    oTButton1 := TButton():New(060, 010, "Selecionar..." ,oContainer,{|| (cPlanilha:=cGetFile("Arquivos CSV | *.csv",OemToAnsi("Selecione Diretorio"),,"",.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)), } , 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDialog:Activate()
Return

Static Function ImportaEndereco(cArquivo)
    Local aLinhas, aCampos, aHeaderLido := {}, aHeaderEsperado := ;
        {"CODIGO", "LOJA", "CEP", "ENDERECO", "COMPLEMENTO", "BAIRRO", "CIDADE", "UF"}
    Local lHeaderValido := .T.
    Local nI, cLinha, cCod, cLoja, cCep, cChave
    Local oDados, nAtualizados := 0, nIgnorados := 0, nCEPErro := 0, nErroAtualizacao := 0

    If !File(cArquivo)
        FWAlertError("Arquivo CSV não encontrado!", "Erro")
        Return
    EndIf

    aLinhas := StrTokArr(MemoRead(cArquivo), Chr(13)+Chr(10))
    If Len(aLinhas) < 2
        FWAlertError("O arquivo deve conter pelo menos o cabeçalho e uma linha de dados.", "Erro")
        Return
    EndIf

    aHeaderLido := StrTokArr(AllTrim(aLinhas[1]), ";")
    If Len(aHeaderLido) != Len(aHeaderEsperado)
        FWAlertError("Cabeçalho inválido: número incorreto de colunas.", "Erro")
        Return
    EndIf

    For nI := 1 To Len(aHeaderEsperado)
        If AllTrim(Upper(aHeaderLido[nI])) != aHeaderEsperado[nI]
            lHeaderValido := .F.
            Exit
        EndIf
    Next

    If !lHeaderValido
        FWAlertError("Cabeçalho inválido. Ordem esperada: " + Join(aHeaderEsperado, ";"), "Erro")
        Return
    EndIf

    If Select("SA1") == 0
        DbSelectArea("SA1")
        SA1->(DbUseArea(.T., "TOPCONN", RetSqlName("SA1"), "SA1", .T., .T.))
    EndIf

    SA1->(DbSetOrder(1))

    For nI := 2 To Len(aLinhas)
        aCampos := StrTokArr(AllTrim(aLinhas[nI]), ";")
        If Len(aCampos) != 8
            nIgnorados++
            Loop
        EndIf

        cCod  := AllTrim(aCampos[1])
        cLoja := AllTrim(aCampos[2])
        cCep  := OnlyNumber(AllTrim(aCampos[3]))

        If Empty(cCep)
            nIgnorados++
            Loop
        EndIf

        oDados := ConsultaCEP(cCep)
        If oDados == NIL
            ConOut("O CEP informado no cadastro de cliente não consta na base de dados da consulta pública. Linha: " + Str(nI))
            nCEPErro++
            Loop
        EndIf

        cChave := PadR(cCod, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1])

        If SA1->(DbSeek(cChave))
            If RecLock("SA1", .F.)
                SA1->A1_CEP     := oDados["cep"]
                SA1->A1_END     := oDados["logradouro"]
                SA1->A1_COMPLEM := oDados["complemento"]
                SA1->A1_BAIRRO  := oDados["bairro"]
                SA1->A1_MUN     := oDados["localidade"]
                SA1->A1_EST     := oDados["uf"]
                MsUnlock()
                ConOut("As informações de endereço do cliente " + cCod + " -> " + SA1->A1_NOME + " foram atualizadas com sucesso.")
                nAtualizados++
            Else
                ConOut("Falha na atualização de endereço do cliente (" + cCod + " -> " + SA1->A1_NOME + "), por favor aguarde alguns instantes e tente novamente.")
                nErroAtualizacao++
            EndIf
        Else
            ConOut("Cliente não encontrado na base: " + cCod + "-" + cLoja)
            nIgnorados++
        EndIf
    Next

    If nAtualizados > 0
        FwAlertSuccess("Importação concluída com sucesso." + CRLF + ;
                    "Clientes atualizados: " + Str(nAtualizados) + CRLF + ;
                    "Ignorados: " + Str(nIgnorados) + CRLF + ;
                    "CEP não localizado: " + Str(nCEPErro) + CRLF + ;
                    "Falhas na atualização: " + Str(nErroAtualizacao), "Resumo")
    Else
        FWAlertError("Nenhum cliente foi atualizado." + CRLF + ;
                     "Ignorados: " + Str(nIgnorados) + CRLF + ;
                     "CEP não localizado: " + Str(nCEPErro) + CRLF + ;
                     "Falhas na atualização: " + Str(nErroAtualizacao), "Erro")
    EndIf
Return



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
            FwAlertInfo("Não foi possível obter resposta do serviço ViaCEP para o CEP informado.", "Consulta CEP")
            Return nil
        EndIf

        oJson:FromJson(cResp)

        If oJson:GetJsonObject("erro") == "true"
            cMensagem := "O CEP informado não consta na base."
            ConOut("[ViaCEP][ERRO] " + cMensagem + " CEP: " + cCEP)
            FwAlertInfo(cMensagem, "Consulta CEP")
            Return nil
        EndIf
        
        If Empty(oJson["logradouro"]) .And. Empty(oJson["bairro"]) .And. ;
           Empty(oJson["localidade"]) .And. Empty(oJson["uf"])
            ConOut("[ViaCEP][ERRO] Dados incompletos no retorno do CEP: " + cCEP)
            FwAlertInfo("Dados incompletos retornados pelo serviço.", "Consulta CEP")
            Return nil
        EndIf

    EndIf

    oResult := oJson

    FWRestArea(aArea)
Return oResult
