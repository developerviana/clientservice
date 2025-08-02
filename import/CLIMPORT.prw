#include 'protheus.ch'
#include 'parmtype.ch'
#Include "rwmake.ch"
#Include 'topconn.ch'
#Include "TbiConn.ch"


User Function CLIMPORT()
    Local cTexto
    Local bConfirm
    Local bSair

    Local oDialog
    Local oContainer
    Public cSuccessCount := 0
    Public lTableCleaned := .F.

    Private cPlanilha  := ""
    Public oExcel 
    Private aOpcoes := {}
    Private cAbas := ""
    Private dDataIni := sToD("")
    Private dDataFin := sToD("")
     
    Private oTGet1
    Private oTGet2
    Private oTButton1

    bConfirm := {|| FwMsgRun(,{|oSay| ImportaPlanilha(oContainer, aOpcoes), NIL}, 'Buscando Planilha ... ', "",) }
    bSair := {|| Iif(MsgYesNo('Voc� tem certeza que deseja sair da rotina?', 'Sair da rotina'), (oDialog:DeActivate()), NIL) }

    oDialog := FWDialogModal():New()

    oDialog:SetBackground(.T.)
    oDialog:SetTitle('Importa��o de Contabilidade Gerencial')
    oDialog:SetSize(200, 280) 
    oDialog:EnableFormBar(.T.)
    oDialog:SetCloseButton(.F.)
    oDialog:SetEscClose(.F.)  
    oDialog:CreateDialog()
    oDialog:CreateFormBar()
    oDialog:AddButton('Importar', bConfirm, 'Confirmar', , .T., .F., .T.)
    oDialog:AddButton('Sair', bSair, 'Sair', , .T., .F., .T.)
    
    oContainer := TPanel():New( ,,, oDialog:getPanelMain() )
    oContainer:Align := CONTROL_ALIGN_ALLCLIENT

    cTexto := 'Incluir registros de contabilidade.'

    oSay2 := TSay():New(010,010,{||cTexto},oContainer,,,,,,.T.,,,800,20)

    // Adiciona campos para selecionar a planilha
    oSay1 := TSay():New(035,010,{||'Selecione a Planilha:'},oContainer,,,,,,.T.,,,100,9)
    oTGet0 := tGet():New(045,010,{|u| if(PCount()>0,cPlanilha:=u,cPlanilha)},oContainer ,180,9,"",,,,,,,.T.,,, {|| .T. } ,,,,.F.,,,"cPlanilha")

    // Fun��o chamada para selecionar a planilha e obter pastas *
    oTButton1 := TButton():New(045, 200, "Selecionar..." ,oContainer,{|| (cPlanilha:=cGetFile("Arquivos Excel | *.xls*",OemToAnsi("Selecione Diretorio"),,"",.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)), FwMsgRun(,{|oSay|PegaAbas(oSay)},'Buscando Planilhas ... ',"",) } , 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )

    // Adiciona campos para selecionar a aba
    oSay5 := TSay():New(065,010,{||'Selecione uma aba da planilha: '},oContainer,,,,,,.T.,,,100,9)
    oCombo1 := TComboBox():New(075,010,{|u|if(PCount()>0,cAbas:=u,cAbas)},aOpcoes,100,9,oContainer,,,,,,.T.,,,,,,,,,'cAbas')    

    oDialog:Activate()
Return

//--------------------------
// Fun��o para extrair as abas da planilha.
//--------------------------
Static Function PegaAbas(oSay)
    Local nContP

    oExcel := YExcel():new(, cPlanilha)
    oExcel:OpenRead(cPlanilha)

    aOpcoes := {}
    For nContP := 1 to oExcel:LenPlanAt()
        oExcel:SetPlanAt(nContP)
        AADD(aOpcoes, ALLTRIM(STR(nContP) + ' - ' + EncodeUtf8(oExcel:GetPlanAt("2"))))
    Next

    If Len(aOpcoes) > 0
        cAbas := aOpcoes[1]
        oCombo1:SetItems(aOpcoes)
        oCombo1:Refresh()
    Else
        FWAlertError("Nenhuma aba encontrada na planilha. Verifique o arquivo e tente novamente.", "Erro")
        Return
    EndIf
Return aOpcoes

//----------------------------------------
// Verificar se a planilha foi selecionada.
//----------------------------------------
Static Function ImportaPlanilha(oContainer, aOpcoes)
    Local lRet := .T.

    If Empty(cPlanilha)
        If oExcel != Nil
            oExcel:Close()
        EndIf
        FWAlertInfo("Por favor, informe a planilha antes de continuar.", "Nenhuma planilha selecionada!")
        lRet := .F.
    EndIf

    If lRet
        If FWAlertNoYes("Confirma a importa��o com os dados informados?", "Importa��o")
            lRet := .T.
            If lRet
                FwMsgRun(,{|oSay| lRet := ProcessarDados(oContainer, aOpcoes)}, 'Validando dados da Planilha. Aguarde ... ', "",)
            EndIf
        Else
            lRet := .F.
        EndIf
    EndIf

Return lRet
//----------------------------------------
// Fun��o para processar e importar dados
//----------------------------------------
Static Function ProcessarDados(oContainer, aOpcoes)

    Local oExcel      := Nil
    Local nLin        := 0
    Local nTotLin     := 0
    Local aLista      := {} 
    Local oJson
    Local cEncontraFilial

    oExcel := YExcel():New(, cPlanilha)
    oExcel:OpenRead(cPlanilha)
    oExcel:SetPlanAt(oCombo1:nAt)

    cEncontraFilial := oExcel:GetValue(1, 1)
    If Alltrim(cEncontraFilial) != "Filial"
        FWAlertInfo("Colunas de importa��o n�o encontradas!", "Aten��o")
        Return
    EndIf    

    nTotLin := oExcel:LinTam()

    For nLin := 3 To nTotLin[2]

        oJson := JsonObject():New()

        oJson["Z2_FILIAL"] := Alltrim(oExcel:GetValue(nLin, 1))
        oJson["Z2_CODORC"] := Alltrim(oExcel:GetValue(nLin, 2))
        oJson["Z2_POSIC"] := Alltrim(oExcel:GetValue(nLin, 3))
        oJson["Z2_FUNDER"] := Alltrim(oExcel:GetValue(nLin, 4))
        oJson["Z2_LOJA"] := Alltrim(oExcel:GetValue(nLin, 5))
        oJson["Z2_FUNDESC"] := Alltrim(oExcel:GetValue(nLin, 6))
        oJson["Z2_PAIS"] := Alltrim(oExcel:GetValue(nLin, 7))
        oJson["Z2_ORIGEM"] := Alltrim(oExcel:GetValue(nLin, 8))
        oJson["Z2_CAPTAC"] := Val(oExcel:GetValue(nLin, 9))
        oJson["Z2_NUMCT"] := Alltrim(oExcel:GetValue(nLin, 10))
        oJson["Z2_ANO"] := Alltrim(oExcel:GetValue(nLin, 11))
        oJson["Z2_ATIVID"] := Alltrim(oExcel:GetValue(nLin, 12))
        oJson["Z2_DETATIV"] := Alltrim(oExcel:GetValue(nLin, 13))
        oJson["Z2_DTINIC"] := CtoD(oExcel:GetValue(nLin, 14))
        oJson["Z2_DTFIM"] := CtoD(oExcel:GetValue(nLin, 15))
        oJson["Z2_MOEDATP"] := Alltrim(oExcel:GetValue(nLin, 16))
        oJson["Z2_VLMOEDA"] := Val(oExcel:GetValue(nLin, 17))
        oJson["Z2_VLUSD"] := Val(oExcel:GetValue(nLin, 18))
        oJson["Z2_TPRECUR"] := Alltrim(oExcel:GetValue(nLin, 19))
        oJson["Z2_VLLINHA"] := Val(oExcel:GetValue(nLin, 20))
        oJson["Z2_CAMBORC"] := Val(oExcel:GetValue(nLin, 21))
        oJson["Z2_VLBRORC"] := Val(oExcel:GetValue(nLin, 22))
        oJson["Z2_CAMBFIN"] := Val(oExcel:GetValue(nLin, 23))
        oJson["Z2_VLBRCON"] := Val(oExcel:GetValue(nLin, 24))
        oJson["Z2_VLDUSD"] := Val(oExcel:GetValue(nLin, 25))
        oJson["Z2_STATUS"] := Alltrim(oExcel:GetValue(nLin, 26))
        oJson["Z2_ITEMC"] := Alltrim(oExcel:GetValue(nLin, 27))
        oJson["Z2_ICDESC"] := Alltrim(oExcel:GetValue(nLin, 28))
        oJson["Z2_CC"] := Alltrim(oExcel:GetValue(nLin, 29))
        oJson["Z2_CCDESC1"] := Alltrim(oExcel:GetValue(nLin, 30))
        oJson["Z2_CCDESC"] := Alltrim(oExcel:GetValue(nLin, 31))
        oJson["Z2_CCDESC2"] := Alltrim(oExcel:GetValue(nLin, 32))
        oJson["Z2_CLASSE"] := Alltrim(oExcel:GetValue(nLin, 33))
        oJson["Z2_CLDESC"] := Alltrim(oExcel:GetValue(nLin, 34))
        oJson["Z2_SUGPE"] := Alltrim(oExcel:GetValue(nLin, 35))
        oJson["Z2_OBSDATA"] := Alltrim(oExcel:GetValue(nLin, 36))
        oJson["Z2_VLFLUXX"] := Val(oExcel:GetValue(nLin, 37))
        oJson["Z2_DIFEREN"] := Val(oExcel:GetValue(nLin, 38))
        oJson["Z2_STATUS2"] := Alltrim(oExcel:GetValue(nLin, 39))
        oJson["Z2_DTMESAT"] := CtoD(oExcel:GetValue(nLin, 40))
        oJson["Z2_CC1"] := ""
        oJson["Z2_CC2"] := ""
        oJson["Z2_PRAZO"] := 0
        oJson["Z2_STATDES"] := ""
        oJson["LINHA"] := nLin
        AAdd(aLista, oJson)

    Next

    FinalizaImport(oExcel, nLin, @aLista)
Return aLista
    
    FinalizaImport(oExcel, nLin, @aLista)
Return aLista

//----------------------------------------
// Verificar se a importa��o deve ser conclu�da
//----------------------------------------
Static Function FinalizaImport(oExcel, nLin, aLista)

    Local oJson 
    Local LinTam := Len(aLista)
    Local i := 0
    Local lExiste := .F.
    Local cFil := ""
    Local cCODORC := ""

    TableClean()
    
    DbSelectArea("SZ2")

    For i := 1 To LinTam

        oJson := aLista[i]
        lExiste := .F.

        cFil := Iif(ValType(oJson["Filial"]) == "C", oJson["Filial"], "")
        cCODORC := Iif(ValType(oJson["Sequencia"]) == "N", Alltrim(Str(oJson["Sequencia"])), "")

        DbGoTop()
        While !EOF()
            If (SZ2->Z2_FILIAL == cFil) .AND. (SZ2->Z2_CODORC == cCODORC)    
                lExiste := .T.
                Exit
            EndIf
            DbSkip()
        EndDo

        If !lExiste

           RecLock("SZ2", .T.)
                SZ2->Z2_FILIAL   := Iif(ValType(oJson["Z2_FILIAL"]) == "C", Alltrim(oJson["Z2_FILIAL"]), "")
                SZ2->Z2_CODORC   := Iif(ValType(oJson["Z2_CODORC"]) == "C", Alltrim(oJson["Z2_CODORC"]), "")
                SZ2->Z2_POSIC    := Iif(ValType(oJson["Z2_POSIC"]) == "C", Alltrim(oJson["Z2_POSIC"]), "")
                SZ2->Z2_FUNDER   := Iif(ValType(oJson["Z2_FUNDER"]) == "C", Alltrim(oJson["Z2_FUNDER"]), "")
                SZ2->Z2_LOJA     := Iif(ValType(oJson["Z2_LOJA"]) == "C", Alltrim(oJson["Z2_LOJA"]), "")
                SZ2->Z2_FUNDESC  := Iif(ValType(oJson["Z2_FUNDESC"]) == "C", Alltrim(oJson["Z2_FUNDESC"]), "")
                SZ2->Z2_CAPTAC   := Iif(ValType(oJson["Z2_CAPTAC"]) == "N", oJson["Z2_CAPTAC"], 0)
                SZ2->Z2_NUMCT    := Iif(ValType(oJson["Z2_NUMCT"]) == "C", Alltrim(oJson["Z2_NUMCT"]), "")
                SZ2->Z2_ANO      := Iif(ValType(oJson["Z2_ANO"]) == "C", Alltrim(oJson["Z2_ANO"]), "")
                SZ2->Z2_ITEMC    := Iif(ValType(oJson["Z2_ITEMC"]) == "C", Alltrim(oJson["Z2_ITEMC"]), "")
                SZ2->Z2_ICDESC   := Iif(ValType(oJson["Z2_ICDESC"]) == "C", Alltrim(oJson["Z2_ICDESC"]), "")
                SZ2->Z2_ATIVID   := Iif(ValType(oJson["Z2_ATIVID"]) == "C", Alltrim(oJson["Z2_ATIVID"]), "")
                SZ2->Z2_DETATIV  := Iif(ValType(oJson["Z2_DETATIV"]) == "C", oJson["Z2_DETATIV"], "")
                SZ2->Z2_DTINIC   := Iif(ValType(oJson["Z2_DTINIC"]) == "D", oJson["Z2_DTINIC"], Ctod(""))
                SZ2->Z2_DTFIM    := Iif(ValType(oJson["Z2_DTFIM"]) == "D", oJson["Z2_DTFIM"], Ctod(""))
                SZ2->Z2_VLMOEDA  := Iif(ValType(oJson["Z2_VLMOEDA"]) == "N", oJson["Z2_VLMOEDA"], 0)
                SZ2->Z2_VLUSD    := Iif(ValType(oJson["Z2_VLUSD"]) == "N", oJson["Z2_VLUSD"], 0)
                SZ2->Z2_TPRECUR  := Iif(ValType(oJson["Z2_TPRECUR"]) == "C", Alltrim(oJson["Z2_TPRECUR"]), "")
                SZ2->Z2_CC       := Iif(ValType(oJson["Z2_CC"]) == "C", Alltrim(oJson["Z2_CC"]), "")
                SZ2->Z2_CCDESC   := Iif(ValType(oJson["Z2_CCDESC"]) == "C", Alltrim(oJson["Z2_CCDESC"]), "")
                SZ2->Z2_MOEDATP  := Iif(ValType(oJson["Z2_MOEDATP"]) == "C", Alltrim(oJson["Z2_MOEDATP"]), "")
                SZ2->Z2_CC1      := Iif(ValType(oJson["Z2_CC"]) == "C", Alltrim(oJson["Z2_CC"]), "")
                SZ2->Z2_CCDESC1  := Iif(ValType(oJson["Z2_CCDESC1"]) == "C", Alltrim(oJson["Z2_CCDESC1"]), "")
                SZ2->Z2_CC2      := Iif(ValType(oJson["Z2_CC"]) == "C", Alltrim(oJson["Z2_CC"]), "")
                SZ2->Z2_CCDESC2  := Iif(ValType(oJson["Z2_CCDESC2"]) == "C", Alltrim(oJson["Z2_CCDESC2"]), "")
                SZ2->Z2_CLASSE   := Iif(ValType(oJson["Z2_CLASSE"]) == "C", Alltrim(oJson["Z2_CLASSE"]), "")
                SZ2->Z2_CLDESC   := Iif(ValType(oJson["Z2_CLDESC"]) == "C", Alltrim(oJson["Z2_CLDESC"]), "")
                SZ2->Z2_VLLINHA  := Iif(ValType(oJson["Z2_VLLINHA"]) == "N", oJson["Z2_VLLINHA"], 0)
                SZ2->Z2_CAMBORC  := Iif(ValType(oJson["Z2_CAMBORC"]) == "N", oJson["Z2_CAMBORC"], 0)
                SZ2->Z2_VLBRORC  := Iif(ValType(oJson["Z2_VLBRORC"]) == "N", oJson["Z2_VLBRORC"], 0)
                SZ2->Z2_CAMBFIN  := Iif(ValType(oJson["Z2_CAMBFIN"]) == "N", oJson["Z2_CAMBFIN"], 0)
                SZ2->Z2_VLBRCON  := Iif(ValType(oJson["Z2_VLBRCON"]) == "N", oJson["Z2_VLBRCON"], 0)
                SZ2->Z2_VLDUSD   := Iif(ValType(oJson["Z2_VLDUSD"]) == "N", oJson["Z2_VLDUSD"], 0)
                SZ2->Z2_STATUS   := Iif(ValType(oJson["Z2_STATUS"]) == "C", Alltrim(oJson["Z2_STATUS"]), "")
                SZ2->Z2_STATDES  := Iif(ValType(oJson["Z2_STATUS"]) == "C", Alltrim(oJson["Z2_STATUS"]), "")
                SZ2->Z2_OBSDATA  := Iif(ValType(oJson["Z2_OBSDATA"]) == "C", oJson["Z2_OBSDATA"], "")
                SZ2->Z2_VLFLUXX  := Iif(ValType(oJson["Z2_VLFLUXX"]) == "N", oJson["Z2_VLFLUXX"], 0)
                SZ2->Z2_DIFEREN  := Iif(ValType(oJson["Z2_DIFEREN"]) == "N", oJson["Z2_DIFEREN"], 0)
                SZ2->Z2_STATUS2  := Iif(ValType(oJson["Z2_STATUS2"]) == "C", Alltrim(oJson["Z2_STATUS2"]), "")
                SZ2->Z2_DTMESAT  := Iif(ValType(oJson["Z2_DTMESAT"]) == "D", oJson["Z2_DTMESAT"], Ctod(""))
                SZ2->Z2_PRAZO    := Iif(ValType(oJson["Z2_PRAZO"]) == "N", oJson["Z2_PRAZO"], 0)
                SZ2->Z2_PAIS     := Iif(ValType(oJson["Z2_PAIS"]) == "C", Alltrim(oJson["Z2_PAIS"]), "")
                SZ2->Z2_ORIGEM   := Iif(ValType(oJson["Z2_ORIGEM"]) == "C", Alltrim(oJson["Z2_ORIGEM"]), "")
                SZ2->Z2_SUGPE    := Iif(ValType(oJson["Z2_SUGPE"]) == "C", Alltrim(oJson["Z2_SUGPE"]), "")
            SZ2->(MsUnLock())

        Else
            FWAlertError("Registro duplicado: ", "Erro")
        EndIf

    Next

    FWAlertInfo("Importa��o Realizada com sucesso!", "Sucesso")
Return .T.


//--------------------------
// Apaga registro de importa��es anteriores.
//--------------------------
Static Function TableClean()
    If !lTableCleaned
        cQuery1 := "DELETE FROM " + RetSqlName("SZ2")
        
        If TCSQLExec(cQuery1) == 0
            lTableCleaned = .T. 
        Else
            FWAlertError("N�o foi poss�vel limpar a tabela SZ2.", "Erro")
        Endif
    Endif
Return

