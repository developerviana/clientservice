#INCLUDE 'Protheus.ch'
#INCLUDE 'Parmtype.ch'
#INCLUDE 'FWMVCDef.ch'
#INCLUDE 'FWMBrowse.ch'

User function CLIMVC()

    Local oBrowse := Nil
    Private aRotina := FwLoadMenuDef("CLIMVC")

    DbSelectArea("SA1")
    SetFunName("CLIMVC")

    oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SA1")
    oBrowse:SetDescription("Atualiza��o de Endere�os de Clientes")
    
    oBrowse:SetFields(GetBrowseFields())

    oBrowse:AddLegend("Empty(SA1->A1_CEP)", "RED","CEP em branco")
    oBrowse:AddLegend("!Empty(SA1->A1_CEP) .And. (Empty(SA1->A1_END) .Or. Empty(SA1->A1_BAIRRO) .Or. Empty(SA1->A1_MUN) .Or. Empty(SA1->A1_EST))", "YELLOW", "Endere�o incompleto")
    oBrowse:AddLegend("!Empty(SA1->A1_CEP) .And. !Empty(SA1->A1_END) .And. !Empty(SA1->A1_BAIRRO) .And. !Empty(SA1->A1_MUN) .And. !Empty(SA1->A1_EST)", "GREEN", "Endere�o completo")
        
    oBrowse:Activate()
Return(Nil)

Static Function MenuDef()
   
    Local aRotina := {}
    
    ADD OPTION aRotina TITLE 'Visualizar'                    ACTION 'VIEWDEF.CLIMVC'      OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar Endere�o'              ACTION 'VIEWDEF.CLIMVC'      OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Legendas'                      ACTION 'U_CLILEGEND'         OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Atualizar por CEP (Manual)'    ACTION 'U_CLIATUALIZACEP'    OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Importa��o CSV (Massa)'        ACTION 'U_CLIMPORT'          OPERATION 3 ACCESS 0

Return aRotina

Static Function ModelDef()

    Local oModel as object
    Local oStMaster as object

    oModel := MPFormModel():New("MODEL_CLIEND", /*bPre*/, {|oModel| ValidModel(oModel)}, /*bCommit*/, /*bCancel*/)

    oStMaster := FWFormStruct(1, 'SA1')
    
    oStMaster := GetModelStruct()

    oModel:AddFields("ModelSA1", /*cOwner*/, oStMaster)
    oModel:SetPrimaryKey({'A1_FILIAL', 'A1_COD', 'A1_LOJA'})
    
    oModel:SetDescription("Atualiza��o de Endere�os de Clientes")
    oModel:GetModel("ModelSA1"):SetDescription("Dados de Endere�o")

Return oModel

Static Function ViewDef()
    Local oView as object
    Local oModel as object
    Local oStMaster as object
    
    oView := FwFormView():New()
    oModel := ModelDef()

    oStMaster := GetViewStruct()

    oView:SetModel(oModel)
    oView:AddField("ViewSA1", oStMaster, "ModelSA1")
   
    oView:CreateHorizontalBox('BoxHeader', 30)
    oView:CreateHorizontalBox('BoxEndereco', 70)

    oView:SetOwnerView('ViewSA1', 'BoxEndereco')
    
    oView:SetDescription("Atualiza��o de Endere�os de Clientes")
    
Return oView

Static Function GetBrowseFields()
	Local aFields := {}

	aAdd(aFields, { "C�digo",    {|| SA1->A1_COD } })
	aAdd(aFields, { "Loja",      {|| SA1->A1_LOJA } })
	aAdd(aFields, { "Nome",      {|| SA1->A1_NOME } })
	aAdd(aFields, { "CEP",       {|| SA1->A1_CEP } })
	aAdd(aFields, { "UF",        {|| SA1->A1_EST } })
	aAdd(aFields, { "Cidade",    {|| SA1->A1_MUN } })
	aAdd(aFields, { "Endereco",  {|| SA1->A1_END } })
	aAdd(aFields, { "Bairro",    {|| SA1->A1_BAIRRO } })
	aAdd(aFields, { "Complemento",{|| SA1->A1_COMPLEM } })

Return aFields


Static Function GetModelStruct()
    Local oStruct := FWFormStruct(1, 'SA1')
    Local aFields := {"A1_COD", "A1_LOJA", "A1_NOME", "A1_CEP", "A1_END", "A1_BAIRRO", ;
                      "A1_EST", "A1_MUN", "A1_COMPLEM"}
    Local aAllFields := oStruct:GetFields()
    Local aFieldsCopy := aClone(aAllFields) 

    Local nI := 0

    For nI := 1 To Len(aFieldsCopy)
        If ValType(aFieldsCopy[nI]) == "A"
            If Len(aFieldsCopy[nI]) >= 3 .And. aScan(aFields, aFieldsCopy[nI][3]) == 0
                oStruct:RemoveField(aFieldsCopy[nI][3])
            EndIf
        EndIf
    Next nI

    oStruct:SetProperty("A1_COD",  MODEL_FIELD_WHEN, {|| .F.}) 
    oStruct:SetProperty("A1_LOJA", MODEL_FIELD_WHEN, {|| .F.}) 
    oStruct:SetProperty("A1_NOME", MODEL_FIELD_WHEN, {|| .F.}) 

Return oStruct


Static Function GetViewStruct()
    Local oStruct := FWFormStruct(2, 'SA1')
    Local aFields := {"A1_COD", "A1_LOJA", "A1_NOME", "A1_CEP", "A1_END", "A1_BAIRRO", ;
                      "A1_EST", "A1_MUN", "A1_COMPLEM"}
    Local aAllFields := oStruct:GetFields()
    Local aFieldsCopy := aClone(aAllFields)
    Local nI := 0

    For nI := 1 To Len(aFieldsCopy)
        If ValType(aFieldsCopy[nI]) == "A"
            If Len(aFieldsCopy[nI]) >= 1 .And. aScan(aFields, aFieldsCopy[nI][1]) == 0
                oStruct:RemoveField(aFieldsCopy[nI][1])
            EndIf
        EndIf
    Next nI

    oStruct:SetProperty("A1_COD",     MVC_VIEW_GROUP_NUMBER, "001")
    oStruct:SetProperty("A1_LOJA",    MVC_VIEW_GROUP_NUMBER, "001")
    oStruct:SetProperty("A1_NOME",    MVC_VIEW_GROUP_NUMBER, "001")

    oStruct:SetProperty("A1_CEP",     MVC_VIEW_GROUP_NUMBER, "002")
    oStruct:SetProperty("A1_END",     MVC_VIEW_GROUP_NUMBER, "002")
    oStruct:SetProperty("A1_COMPLEM", MVC_VIEW_GROUP_NUMBER, "002")
    oStruct:SetProperty("A1_BAIRRO",  MVC_VIEW_GROUP_NUMBER, "002")
    oStruct:SetProperty("A1_MUN",     MVC_VIEW_GROUP_NUMBER, "002")
    oStruct:SetProperty("A1_EST",     MVC_VIEW_GROUP_NUMBER, "002")

Return oStruct


Static Function ValidModel(oModel)
    Local lRet := .T.
    Local cCEP := oModel:GetValue("ModelSA1", "A1_CEP")
    
    If !Empty(cCEP)
        cCEP := StrTran(StrTran(cCEP, "-", ""), ".", "")
        If Len(AllTrim(cCEP)) != 8 .Or. !IsDigit(cCEP)
            Help(,, "CEPINVALIDO",, "CEP deve conter exatamente 8 d�gitos num�ricos", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet


User Function CLILEGEND()
    Local aLegenda := {}
    
    aAdd(aLegenda, {"BR_VERMELHO",    "CEP em branco"})
    aAdd(aLegenda, {"BR_AMARELO", "CEP preenchido, endere�o incompleto"})
    aAdd(aLegenda, {"BR_VERDE",  "Endere�o completo"})
    
    BrwLegenda("Status dos Endere�os", "Legenda", aLegenda)
    
Return


User Function CLICEPMAN()
    Local cCEP := Space(8)
    Local oDlg
    Local oGet
    Local lOk := .F.
    
    If Empty(SA1->A1_COD)
        MsgAlert("Posicione em um cliente para atualizar o endere�o!")
        Return
    EndIf
    
    DEFINE MSDIALOG oDlg TITLE "Atualizar Endere�o por CEP" FROM 000, 000 TO 150, 300 PIXEL
    
    @ 020, 010 SAY "CEP:" SIZE 030, 010 OF oDlg PIXEL
    @ 018, 040 MSGET oGet VAR cCEP SIZE 060, 012 OF oDlg PIXEL PICTURE "@R 99999-999"
    
    @ 050, 050 BUTTON "OK" SIZE 040, 015 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
    @ 050, 100 BUTTON "Cancelar" SIZE 040, 015 OF oDlg PIXEL ACTION oDlg:End()
    
    ACTIVATE MSDIALOG oDlg CENTERED
    
    If lOk .And. !Empty(cCEP)
        Processa({|| AtualizarCEP(cCEP, SA1->A1_COD, SA1->A1_LOJA)}, "Consultando CEP...", "Aguarde...")
    EndIf
    
Return


Static Function AtualizarCEP(cCEP, cCodigo, cLoja)
    // Esta fun��o ser� implementada junto com o webservice ViaCEP
    MsgInfo("Fun��o de atualiza��o por CEP ser� implementada com o webservice!")
Return

User Function CLIATUALIZACEP()
    Local cCEP     := Space(8)
    Local oDlg, oGet
    Local lOk      := .F.
    Local cMensagem
    Local oResult   := Nil

    If Empty(SA1->A1_COD)
        MsgAlert("Posicione em um cliente para atualizar o endere�o!")
        Return
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Atualizar Endere�o por CEP" FROM 000, 000 TO 150, 300 PIXEL
        @ 020, 010 SAY "CEP:" SIZE 030, 010 OF oDlg PIXEL
        @ 018, 040 MSGET oGet VAR cCEP SIZE 060, 012 OF oDlg PIXEL PICTURE "@R 99999-999"
        @ 050, 050 BUTTON "OK" SIZE 040, 015 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
        @ 050, 100 BUTTON "Cancelar" SIZE 040, 015 OF oDlg PIXEL ACTION oDlg:End()
    ACTIVATE MSDIALOG oDlg CENTERED

    If !lOk .Or. Empty(AllTrim(cCEP))
        Return
    EndIf

    cCEP := StrTran(StrTran(cCEP, "-", ""), ".", "")

    If Len(AllTrim(cCEP)) != 8 .Or. !IsDigit(cCEP)
        MsgStop("CEP inv�lido! Deve conter exatamente 8 d�gitos num�ricos.")
        Return
    EndIf

    oResult := WSCEP(cCEP)

    If oResult == Nil .Or. oResult["erro"] == .T.
        cMensagem := "O CEP informado no cadastro de cliente n�o consta na base de dados da consulta p�blica."
        MsgStop(cMensagem)
        ConOut("[WSCEP][ERRO] " + cMensagem + " CEP: " + cCEP)
        Return
    EndIf

    DbSelectArea("SA1")
    If MsSeek(xFilial("SA1") + SA1->A1_COD + SA1->A1_LOJA)
        If RecLock("SA1", .F.)
            SA1->A1_CEP     := oResult["cep"]
            SA1->A1_END     := oResult["logradouro"]
            SA1->A1_COMPLEM := oResult["complemento"]
            SA1->A1_BAIRRO  := oResult["bairro"]
            SA1->A1_MUN     := oResult["localidade"]
            SA1->A1_EST     := oResult["uf"]
            MsUnlock()

            cMensagem := "As informa��es de endere�o do cliente " + SA1->A1_COD + " -> " + SA1->A1_NOME + " foram atualizadas com sucesso."
            MsgInfo(cMensagem)
            ConOut("[WSCEP][OK] " + cMensagem)
        Else
            cMensagem := "Falha na atualiza��o de endere�o do cliente (" + SA1->A1_COD + " --> " + SA1->A1_NOME + "), por favor aguarde alguns instantes e tente novamente."
            MsgStop(cMensagem)
            ConOut("[WSCEP][ERRO] " + cMensagem)
        EndIf
    Else
        MsgStop("Cliente n�o localizado!")
    EndIf
Return
