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

    cTexto := "• O Arquivo deverá ser salvo como .CSV antes de ser importado<br>"
    cTexto += "• O Layout deverá seguir o número exato de colunas (8)<br>"
    cTexto += "• O Arquivo não deve conter ';' em suas descrições<br>"

    oSay2 := TSay():New(005,010,{||cTexto},oContainer,,,,,,.T.,,,900,20)

    oSay1 := TSay():New(035,010,{||'Arquivo CSV:'},oContainer,,,,,,.T.,,,100,9)
    oTGet0 := tGet():New(045,010,{|u| if(PCount()>0,cPlanilha:=u,cPlanilha)},oContainer ,180,9,"",,,,,,,.T.,,, {|| .T. } ,,,,.F.,,,"cPlanilha")

    oTButton1 := TButton():New(060, 010, "Selecionar..." ,oContainer,{|| (cPlanilha:=cGetFile("Arquivos CSV | *.csv",OemToAnsi("Selecione Diretorio"),,"",.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)), } , 100,10,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDialog:Activate()
Return

Static Function ImportaEndereco(cArquivo)
    Local aHeaderEsperado := {"CODIGO", "LOJA", "CEP", "ENDERECO", "COMPLEMENTO", "BAIRRO", "CIDADE", "UF"}
    Local aHeaderLido := {}
    Local lHeaderValido := .T.
    Local nAtualizados := 0
    Local cLinha, aCampos, cChave
    Local oArquivo, oCliente
    Local aLinhas := {}
    Local nTotLinhas := 0
    Local nLinha := 0
    Local nI := 0

    oArquivo := FWFileReader():New(cArquivo)
    ConOut("Tentando abrir o arquivo: " + cArquivo)

    If !oArquivo:Open()
        ConOut("Falha ao abrir o arquivo: " + cArquivo)
        FWAlertError("Não foi possível abrir o arquivo.", "Erro")
        Return
    EndIf

    ConOut("Arquivo aberto com sucesso: " + cArquivo)

    If oArquivo:EoF()
        FWAlertError("O arquivo está vazio.", "Erro")
        oArquivo:Close()
        Return
    EndIf

    aLinhas := oArquivo:GetAllLines()
    oArquivo:Close()

    nTotLinhas := Len(aLinhas)

    If nTotLinhas < 2
        FWAlertError("O arquivo deve conter ao menos o cabeçalho e uma linha de dados.", "Erro")
        Return
    EndIf

    // Validação do cabeçalho
    aHeaderLido := StrTokArr(AllTrim(aLinhas[1]), ";")

    If Len(aHeaderLido) != Len(aHeaderEsperado)
        lHeaderValido := .F.
    Else
        For nI := 1 To Len(aHeaderEsperado)
            If AllTrim(Upper(aHeaderLido[nI])) != aHeaderEsperado[nI]
                lHeaderValido := .F.
                Exit
            EndIf
        Next
    EndIf

    If !lHeaderValido
        FWAlertError("Cabeçalho inválido. Esperado: " + Join(aHeaderEsperado, ";"), "Erro")
        Return
    EndIf

    
    DbSelectArea("SA1")
    SA1->(DbSetOrder(1)) 

    // Processamento das linhas a partir da linha 02
    For nLinha := 2 To nTotLinhas
        IncProc()
        cLinha := AllTrim(aLinhas[nLinha])

        If Empty(cLinha)
            Loop
        EndIf

        aCampos := StrTokArr(cLinha, ";")
        oCliente := JsonObject():New()

        For nI := 1 To Len(aHeaderEsperado)
            oCliente[ aHeaderEsperado[nI] ] := AllTrim(aCampos[nI])
        Next

        If Empty(oCliente["CEP"])
            ConOut("Linha " + Str(nLinha) + ": CEP não preenchido para o cliente " + oCliente["CODIGO"], "Aviso")
            Loop
        EndIf


        cChave := xFilial("SA1") + ;
                PadR(AllTrim(aCampos[1]), TamSX3("A1_COD")[1]) + ;
                PadR(AllTrim(aCampos[2]), TamSX3("A1_LOJA")[1])

        If SA1->(DbSeek(cChave))
            If RecLock("SA1", .F.)
                SA1->A1_CEP     := AllTrim(aCampos[3])
                SA1->A1_END     := AllTrim(aCampos[4])
                SA1->A1_COMPLEM := AllTrim(aCampos[5])
                SA1->A1_BAIRRO  := AllTrim(aCampos[6])
                SA1->A1_MUN     := AllTrim(aCampos[7])
                SA1->A1_EST     := AllTrim(aCampos[8])
                MsUnlock()
                nAtualizados++
            Else
                FWAlertError("Não foi possível atualizar o cliente na linha " + Str(nLinha) + ": " + aCampos[1] + ". Registro pode estar em uso por outro usuário.", "Aviso")
            EndIf
        Else
            FWAlertError("Cliente não encontrado na linha " + Str(nLinha) + ": " + aCampos[1], "Aviso")
        EndIf
    Next


    FWAlertInfo("Importação finalizada. Clientes atualizados: " + Str(nAtualizados), "Sucesso")
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
