#INCLUDE 'Protheus.ch'
#INCLUDE 'Parmtype.ch'
#INCLUDE 'FWMVCDef.ch'
#INCLUDE 'FWMBrowse.ch'

/*------------------------------------------------------------------------//
//Programa:	 CLIMVC
//Autor:	 Victor
//Descricao: MVC para atualização de endereços de clientes
//------------------------------------------------------------------------*/

User function CLIMVC()

    Local oBrowse := Nil
    Private aRotina := FwLoadMenuDef("CLIMVC")

    DbSelectArea("SA1")
    SetFunName("CLIMVC")

    oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SA1")
    oBrowse:SetDescription("Atualização de Endereços de Clientes")
    
    oBrowse:SetFields(GetBrowseFields())

    oBrowse:AddLegend("Empty(SA1->A1_CEP)", "RED", "CEP em branco")
    oBrowse:AddLegend("!Empty(SA1->A1_CEP) .And. (Empty(SA1->A1_END) .Or. Empty(SA1->A1_BAIRRO) .Or. Empty(SA1->A1_MUN) .Or. Empty(SA1->A1_EST) .Or. Empty(SA1->A1_COMPLEM))", "YELLOW", "Endereço incompleto")
    oBrowse:AddLegend("!Empty(SA1->A1_CEP) .And. !Empty(SA1->A1_END) .And. !Empty(SA1->A1_BAIRRO) .And. !Empty(SA1->A1_MUN) .And. !Empty(SA1->A1_EST) .And. !Empty(SA1->A1_COMPLEM)", "GREEN", "Endereço completo")
        
    oBrowse:Activate()
Return(Nil)

Static Function MenuDef()
   
    Local aRotina := {}
    
    ADD OPTION aRotina TITLE 'Visualizar'                    ACTION 'VIEWDEF.CLIMVC'      OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Legendas'                      ACTION 'U_CLILEGEND'         OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Atualizar por CEP (Manual)'    ACTION 'U_CLIATUALIZACEP'    OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Importação CSV (Massa)'        ACTION 'U_CLIMPORT'          OPERATION 4 ACCESS 0

Return aRotina

Static Function ModelDef()

    Local oModel as object
    Local oStMaster as object

    oModel := MPFormModel():New("MODEL_CLIEND", /*bPre*/, {|oModel| ValidModel(oModel)}, /*bCommit*/, /*bCancel*/)

    oStMaster := FWFormStruct(1, 'SA1')
    
    oStMaster := GetModelStruct()

    oModel:AddFields("ModelSA1", /*cOwner*/, oStMaster)
    oModel:SetPrimaryKey({'A1_FILIAL', 'A1_COD', 'A1_LOJA'})
    
    oModel:SetDescription("Atualização de Endereços de Clientes")
    oModel:GetModel("ModelSA1"):SetDescription("Dados de Endereço")

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
    
    oView:SetDescription("Atualização de Endereços de Clientes")
    
Return oView

Static Function GetBrowseFields()
	Local aFields := {}

	aAdd(aFields, { "Código",    {|| SA1->A1_COD } })
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
            Help(,, "CEPINVALIDO",, "CEP deve conter exatamente 8 dígitos numéricos", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet

User Function CLILEGEND()
    Local aLegenda := {}
    
    aAdd(aLegenda, {"BR_VERMELHO",    "CEP em branco"})
    aAdd(aLegenda, {"BR_AMARELO", "CEP preenchido, endereço incompleto"})
    aAdd(aLegenda, {"BR_VERDE",  "Endereço completo"})
    
    BrwLegenda("Status dos Endereços", "Legenda", aLegenda)
    
Return

User Function CLIATUALIZACEP()
    Local cCEP     := Space(8)
    Local oDlg, oGet
    Local lOk      := .F.
    Local cMensagem
    Local oResult   := Nil

    If Empty(SA1->A1_COD)
        MsgAlert("Posicione em um cliente para atualizar o endereço!")
        Return
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Atualizar Endereço por CEP" FROM 000, 000 TO 150, 300 PIXEL
        @ 020, 010 SAY "CEP:" SIZE 030, 010 OF oDlg PIXEL
        @ 018, 040 MSGET oGet VAR cCEP SIZE 060, 012 OF oDlg PIXEL PICTURE "@R 99999-999" VALID (IsCepValid(cCEP))
        @ 050, 050 BUTTON "OK" SIZE 040, 015 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
        @ 050, 100 BUTTON "Cancelar" SIZE 040, 015 OF oDlg PIXEL ACTION oDlg:End()
    ACTIVATE MSDIALOG oDlg CENTERED

    If !lOk .Or. Empty(AllTrim(cCEP))
        Return
    EndIf

    oResult := WSCEP(cCEP)

    If oResult == Nil
        Return
    EndIf

    If oResult != Nil
        oResult := NormalizaViaCEP(oResult)

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

                cMensagem := "As informações de endereço do cliente " + SA1->A1_COD + " -> " + SA1->A1_NOME + " foram atualizadas com sucesso."
                ConOut("[WSCEP][OK] " + cMensagem)
                FwAlertSuccess(cMensagem, "Atualização de Endereço")
            Else
                cMensagem := "Falha na atualização de endereço do cliente (" + SA1->A1_COD + " --> " + SA1->A1_NOME + "), por favor aguarde alguns instantes e tente novamente."
                ConOut("[WSCEP][ERRO] " + cMensagem)
            EndIf
        Else
            FwAlertError("Cliente não localizado!")
        EndIf
    Endif 
Return

Static Function WSCEP(cCEP)
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

Static Function IsCepValid(cCEP)
    Local cCleanCep := AllTrim(StrTran(StrTran(cCEP, "-", ""), ".", ""))

    If Len(cCleanCep) != 8 .Or. !IsDigit(cCleanCep)
        FwAlertError("CEP inválido! Deve conter exatamente 8 dígitos numéricos (somente números).")
        ConOut("[CLIATUALIZACEP][ERRO] CEP inválido informado: " + cCEP)
        Return .F.
    EndIf

Return .T.

Static Function NormalizaViaCEP(oResult)
    Local oTratado := JsonObject():New()

    oTratado["cep"]        := StrTran(oResult["cep"], "-", "")
    oTratado["logradouro"] := LimpaTexto(AllTrim(oResult["logradouro"]))
    oTratado["complemento"]:= LimpaTexto(AllTrim(oResult["complemento"]))
    oTratado["bairro"]     := LimpaTexto(AllTrim(oResult["bairro"]))
    oTratado["localidade"] := LimpaTexto(AllTrim(oResult["localidade"]))
    oTratado["uf"]         := Upper(AllTrim(oResult["uf"]))

Return oTratado

Static Function LimpaTexto(cTexto)
    Local c := FWNoAccent(AllTrim(cTexto))
    Local i, cRes := "", lNovaPalavra := .T.
    Local cChar

    For i := 1 To Len(c)
        cChar := SubStr(c, i, 1)

        If IsAlpha(cChar) .Or. IsDigit(cChar) .Or. cChar == " "
            If cChar == " "
                lNovaPalavra := .T.
                cRes += cChar
            Else
                If lNovaPalavra
                    cRes += cChar 
                    lNovaPalavra := .F.
                Else
                    cRes += Lower(cChar)
                EndIf
            EndIf
        EndIf
    Next

Return cRes

