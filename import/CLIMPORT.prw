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

    oTButton1 := TButton():New(055, 010, "Selecionar..." ,oContainer,{|| (cPlanilha:=cGetFile("Arquivos CSV | *.csv",OemToAnsi("Selecione Diretorio"),,"",.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)), FwMsgRun(,{|oSay|PegaAbas(oSay)},'Buscando Planilhas ... ',"",) } , 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDialog:Activate()
Return

Static Function ImportaEndereco(cArquivo)
    Local aLinhas, aCampos, nI, cLinha
    Local aHeaderEsperado := {"CODIGO", "LOJA", "CEP", "ENDERECO", "COMPLEMENTO", "BAIRRO", "CIDADE", "UF"}
    Local aHeaderLido := {}
    Local lHeaderValido := .T.
    Local nAtualizados := 0
    Local cChave

    If !File(cArquivo)
        FWAlertError("Arquivo CSV não encontrado!", "Erro")
        Return
    EndIf

    aLinhas := MemoRead(cArquivo)
    aLinhas := StrTokArr(aLinhas, Chr(13)+Chr(10))

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
        cLinha := AllTrim(aLinhas[nI])
        If Empty(cLinha)
            Loop
        EndIf

        aCampos := StrTokArr(cLinha, ";")

        If Len(aCampos) != 8
            FWAlertError("Linha " + Str(nI) + " com número incorreto de colunas.", "Erro")
            Loop
        EndIf

        cChave := PadR(AllTrim(aCampos[1]), TamSX3("A1_COD")[1]) + PadR(AllTrim(aCampos[2]), TamSX3("A1_LOJA")[1])

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
                FWAlertError("Erro ao dar lock na linha " + Str(nI) + " [" + aCampos[1] + "-" + aCampos[2] + "]", "Erro")
            EndIf
        Else
            FWAlertError("Cliente não encontrado na linha " + Str(nI) + ": " + aCampos[1] + "-" + aCampos[2], "Aviso")
        EndIf
    Next

    FWAlertInfo("Importação finalizada. Clientes atualizados: " + Str(nAtualizados), "Sucesso")
Return

