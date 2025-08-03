#INCLUDE 'Protheus.ch'
#INCLUDE 'Parmtype.ch'
#INCLUDE 'FWMVCDef.ch'
#INCLUDE 'FWMBrowse.ch'

/*------------------------------------------------------------------------//
//Programa:	 CLICAD
//Autor:	 Victor
//Descricao: MVC para cadastro completo de clientes
//------------------------------------------------------------------------*/

User function CLICAD()

    Local oBrowse := Nil
    Private aRotina := FwLoadMenuDef("CLICAD")

    DbSelectArea("SA1")
    SetFunName("CLICAD")

    oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SA1")
    oBrowse:SetDescription("Cadastro de Clientes")
    
    oBrowse:SetFields(GetBrowseFields())

    oBrowse:AddLegend("SA1->A1_MSBLQL == '1'", "RED", "Cliente Bloqueado")
    oBrowse:AddLegend("SA1->A1_MSBLQL != '1' .And. Empty(SA1->A1_CEP)", "YELLOW", "Cliente sem CEP")
    oBrowse:AddLegend("SA1->A1_MSBLQL != '1' .And. !Empty(SA1->A1_CEP)", "GREEN", "Cliente Ativo")
        
    oBrowse:Activate()
Return(Nil)

Static Function MenuDef()
   
    Local aRotina := {}
    
    ADD OPTION aRotina TITLE 'Visualizar'             ACTION 'VIEWDEF.CLICAD'      OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Incluir'               ACTION 'VIEWDEF.CLICAD'      OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'               ACTION 'VIEWDEF.CLICAD'      OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Excluir'               ACTION 'VIEWDEF.CLICAD'      OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE 'Legendas'              ACTION 'U_CADLEGEND'         OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Consultar CEP'         ACTION 'U_CADCONSULTACEP'    OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Importação CSV'        ACTION 'U_CADIMPORT'         OPERATION 4 ACCESS 0

Return aRotina

Static Function ModelDef()

    Local oModel as object
    Local oStMaster as object

    oModel := MPFormModel():New("MODEL_CLICAD", /*bPre*/, {|oModel| ValidModel(oModel)}, /*bCommit*/, /*bCancel*/)

    oStMaster := FWFormStruct(1, 'SA1')
    
    // Customizações na estrutura do modelo
    oStMaster:SetProperty("A1_COD",    MODEL_FIELD_VALID, {|oModel,cField,xNewValue,xOldValue| ValidaCodigo(oModel,cField,xNewValue,xOldValue)})
    oStMaster:SetProperty("A1_CGC",    MODEL_FIELD_VALID, {|oModel,cField,xNewValue,xOldValue| ValidaCNPJCPF(oModel,cField,xNewValue,xOldValue)})
    oStMaster:SetProperty("A1_CEP",    MODEL_FIELD_VALID, {|oModel,cField,xNewValue,xOldValue| ValidaCEP(oModel,cField,xNewValue,xOldValue)})
    oStMaster:SetProperty("A1_EMAIL",  MODEL_FIELD_VALID, {|oModel,cField,xNewValue,xOldValue| ValidaEmail(oModel,cField,xNewValue,xOldValue)})

    oModel:AddFields("ModelSA1", /*cOwner*/, oStMaster)
    oModel:SetPrimaryKey({'A1_FILIAL', 'A1_COD', 'A1_LOJA'})
    
    oModel:SetDescription("Cadastro de Clientes")
    oModel:GetModel("ModelSA1"):SetDescription("Dados do Cliente")

Return oModel

Static Function ViewDef()
    Local oView as object
    Local oModel as object
    Local oStMaster as object
    
    oView := FwFormView():New()
    oModel := ModelDef()

    oStMaster := FWFormStruct(2, 'SA1')

    // Customizações na view
    oStMaster:SetProperty("A1_COD",     MVC_VIEW_GROUP_NUMBER, "001")
    oStMaster:SetProperty("A1_LOJA",    MVC_VIEW_GROUP_NUMBER, "001")
    oStMaster:SetProperty("A1_NOME",    MVC_VIEW_GROUP_NUMBER, "001")
    oStMaster:SetProperty("A1_NREDUZ",  MVC_VIEW_GROUP_NUMBER, "001")
    oStMaster:SetProperty("A1_TIPO",    MVC_VIEW_GROUP_NUMBER, "001")
    oStMaster:SetProperty("A1_PESSOA",  MVC_VIEW_GROUP_NUMBER, "001")
    
    oStMaster:SetProperty("A1_CGC",     MVC_VIEW_GROUP_NUMBER, "002")
    oStMaster:SetProperty("A1_INSCR",   MVC_VIEW_GROUP_NUMBER, "002")
    oStMaster:SetProperty("A1_INSCRM",  MVC_VIEW_GROUP_NUMBER, "002")
    
    oStMaster:SetProperty("A1_CEP",     MVC_VIEW_GROUP_NUMBER, "003")
    oStMaster:SetProperty("A1_END",     MVC_VIEW_GROUP_NUMBER, "003")
    oStMaster:SetProperty("A1_COMPLEM", MVC_VIEW_GROUP_NUMBER, "003")
    oStMaster:SetProperty("A1_BAIRRO",  MVC_VIEW_GROUP_NUMBER, "003")
    oStMaster:SetProperty("A1_MUN",     MVC_VIEW_GROUP_NUMBER, "003")
    oStMaster:SetProperty("A1_EST",     MVC_VIEW_GROUP_NUMBER, "003")
    
    oStMaster:SetProperty("A1_DDD",     MVC_VIEW_GROUP_NUMBER, "004")
    oStMaster:SetProperty("A1_TEL",     MVC_VIEW_GROUP_NUMBER, "004")
    oStMaster:SetProperty("A1_FAX",     MVC_VIEW_GROUP_NUMBER, "004")
    oStMaster:SetProperty("A1_EMAIL",   MVC_VIEW_GROUP_NUMBER, "004")
    
    oStMaster:SetProperty("A1_VEND",    MVC_VIEW_GROUP_NUMBER, "005")
    oStMaster:SetProperty("A1_COND",    MVC_VIEW_GROUP_NUMBER, "005")
    oStMaster:SetProperty("A1_RISCO",   MVC_VIEW_GROUP_NUMBER, "005")
    oStMaster:SetProperty("A1_LC",      MVC_VIEW_GROUP_NUMBER, "005")

    oView:SetModel(oModel)
    oView:AddField("ViewSA1", oStMaster, "ModelSA1")
   
    oView:CreateHorizontalBox('BoxGeral', 25)
    oView:CreateHorizontalBox('BoxDoctos', 15) 
    oView:CreateHorizontalBox('BoxEndereco', 25)
    oView:CreateHorizontalBox('BoxContato', 15)
    oView:CreateHorizontalBox('BoxComercial', 20)

    oView:SetOwnerView('ViewSA1', 'BoxGeral')
    
    oView:SetDescription("Cadastro de Clientes")
    
    // Botões customizados
    oView:AddUserButton("Consultar CEP", "CONSULTA_CEP", {|| U_CADCONSULTACEP() })
    
Return oView

Static Function GetBrowseFields()
	Local aFields := {}

	aAdd(aFields, { "Código",    {|| SA1->A1_COD } })
	aAdd(aFields, { "Loja",      {|| SA1->A1_LOJA } })
	aAdd(aFields, { "Nome",      {|| SA1->A1_NOME } })
	aAdd(aFields, { "CNPJ/CPF",  {|| SA1->A1_CGC } })
	aAdd(aFields, { "Cidade",    {|| SA1->A1_MUN } })
	aAdd(aFields, { "UF",        {|| SA1->A1_EST } })
	aAdd(aFields, { "Telefone",  {|| SA1->A1_TEL } })
	aAdd(aFields, { "Tipo",      {|| SA1->A1_TIPO } })

Return aFields

Static Function ValidModel(oModel)
    Local lRet := .T.
    Local cCodigo := oModel:GetValue("ModelSA1", "A1_COD")
    Local cLoja := oModel:GetValue("ModelSA1", "A1_LOJA")
    Local cNome := oModel:GetValue("ModelSA1", "A1_NOME")
    
    // Validações obrigatórias
    If Empty(cCodigo)
        Help(,, "CODOBRIGATORIO",, "Código do cliente é obrigatório", 1, 0)
        lRet := .F.
    EndIf
    
    If Empty(cLoja)
        Help(,, "LOJAOBRIGATORIA",, "Loja é obrigatória", 1, 0)
        lRet := .F.
    EndIf
    
    If Empty(cNome)
        Help(,, "NOMEOBRIGATORIO",, "Nome do cliente é obrigatório", 1, 0)
        lRet := .F.
    EndIf
    
Return lRet

Static Function ValidaCodigo(oModel, cField, xNewValue, xOldValue)
    Local lRet := .T.
    Local cCodigo := AllTrim(xNewValue)
    
    If !Empty(cCodigo)
        If Len(cCodigo) < 3
            Help(,, "CODMINIMO",, "Código deve ter no mínimo 3 caracteres", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet

Static Function ValidaCNPJCPF(oModel, cField, xNewValue, xOldValue)
    Local lRet := .T.
    Local cDoc := AllTrim(StrTran(StrTran(StrTran(xNewValue, ".", ""), "/", ""), "-", ""))
    
    If !Empty(cDoc)
        If Len(cDoc) == 11
            // Validação CPF simplificada
            If !IsDigit(cDoc)
                Help(,, "CPFINVALIDO",, "CPF deve conter apenas números", 1, 0)
                lRet := .F.
            EndIf
        ElseIf Len(cDoc) == 14
            // Validação CNPJ simplificada
            If !IsDigit(cDoc)
                Help(,, "CNPJINVALIDO",, "CNPJ deve conter apenas números", 1, 0)
                lRet := .F.
            EndIf
        Else
            Help(,, "DOCINVALIDO",, "Documento deve ter 11 dígitos (CPF) ou 14 dígitos (CNPJ)", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet

Static Function ValidaCEP(oModel, cField, xNewValue, xOldValue)
    Local lRet := .T.
    Local cCEP := AllTrim(StrTran(StrTran(xNewValue, "-", ""), ".", ""))
    
    If !Empty(cCEP)
        If Len(cCEP) != 8 .Or. !IsDigit(cCEP)
            Help(,, "CEPINVALIDO",, "CEP deve conter exatamente 8 dígitos numéricos", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet

Static Function ValidaEmail(oModel, cField, xNewValue, xOldValue)
    Local lRet := .T.
    Local cEmail := AllTrim(xNewValue)
    
    If !Empty(cEmail)
        If "@" $ cEmail .And. "." $ cEmail
            // Validação básica de email
        Else
            Help(,, "EMAILINVALIDO",, "Email deve conter @ e pelo menos um ponto", 1, 0)
            lRet := .F.
        EndIf
    EndIf
    
Return lRet

User Function CADLEGEND()
    Local aLegenda := {}
    
    aAdd(aLegenda, {"BR_VERMELHO", "Cliente Bloqueado"})
    aAdd(aLegenda, {"BR_AMARELO",  "Cliente sem CEP"})
    aAdd(aLegenda, {"BR_VERDE",    "Cliente Ativo"})
    
    BrwLegenda("Status dos Clientes", "Legenda", aLegenda)
    
Return

User Function CADCONSULTACEP()
    Local cCEP     := Space(8)
    Local oDlg, oGet
    Local lOk      := .F.
    Local cMensagem
    Local oResult   := Nil
    Local oModel    := FWModelActive()

    If oModel == Nil
        MsgAlert("Não há modelo ativo para atualizar o endereço!")
        Return
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Consultar e Atualizar Endereço por CEP" FROM 000, 000 TO 150, 300 PIXEL
        @ 020, 010 SAY "CEP:" SIZE 030, 010 OF oDlg PIXEL
        @ 018, 040 MSGET oGet VAR cCEP SIZE 060, 012 OF oDlg PIXEL PICTURE "@R 99999-999" VALID (IsCepValid(cCEP))
        @ 050, 050 BUTTON "OK" SIZE 040, 015 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
        @ 050, 100 BUTTON "Cancelar" SIZE 040, 015 OF oDlg PIXEL ACTION oDlg:End()
    ACTIVATE MSDIALOG oDlg CENTERED

    If !lOk .Or. Empty(AllTrim(cCEP))
        Return
    EndIf

    oResult := ConsultaCEPViaCEP(AllTrim(StrTran(StrTran(cCEP, "-", ""), ".", "")))

    If oResult != Nil
        oResult := NormalizaViaCEP(oResult)
        
        oModel:SetValue("ModelSA1", "A1_CEP",     oResult["cep"])
        oModel:SetValue("ModelSA1", "A1_END",     oResult["logradouro"])
        oModel:SetValue("ModelSA1", "A1_COMPLEM", oResult["complemento"])
        oModel:SetValue("ModelSA1", "A1_BAIRRO",  oResult["bairro"])
        oModel:SetValue("ModelSA1", "A1_MUN",     oResult["localidade"])
        oModel:SetValue("ModelSA1", "A1_EST",     oResult["uf"])

        cMensagem := "Endereço atualizado com sucesso!"
        ConOut("[CADCONSULTACEP][OK] " + cMensagem)
        FwAlertSuccess(cMensagem, "Consulta CEP")
    EndIf
Return

Static Function ConsultaCEPViaCEP(cCEP)
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
            FWRestArea(aArea)
            Return nil
        EndIf

        oJson:FromJson(cResp)

        If oJson:GetJsonObject("erro") == "true"
            cMensagem := "O CEP informado não consta na base."
            ConOut("[ViaCEP][ERRO] " + cMensagem + " CEP: " + cCEP)
            FwAlertInfo(cMensagem, "Consulta CEP")
            FWRestArea(aArea)
            Return nil
        EndIf
        
        If Empty(oJson["logradouro"]) .And. Empty(oJson["bairro"]) .And. ;
           Empty(oJson["localidade"]) .And. Empty(oJson["uf"])
            ConOut("[ViaCEP][ERRO] Dados incompletos no retorno do CEP: " + cCEP)
            FwAlertInfo("Dados incompletos retornados pelo serviço.", "Consulta CEP")
            FWRestArea(aArea)
            Return nil
        EndIf
    Else
        ConOut("[ViaCEP][ERRO] Falha na comunicação com o serviço para CEP: " + cCEP)
        FwAlertInfo("Falha na comunicação com o serviço ViaCEP.", "Consulta CEP")
        FWRestArea(aArea)
        Return nil
    EndIf

    oResult := oJson
    FWRestArea(aArea)
Return oResult

Static Function IsCepValid(cCEP)
    Local cCleanCep := AllTrim(StrTran(StrTran(cCEP, "-", ""), ".", ""))

    If Len(cCleanCep) != 8 .Or. !IsDigit(cCleanCep)
        FwAlertError("CEP inválido! Deve conter exatamente 8 dígitos numéricos.")
        ConOut("[CADCONSULTACEP][ERRO] CEP inválido informado: " + cCEP)
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
                    cRes += Upper(cChar) 
                    lNovaPalavra := .F.
                Else
                    cRes += Lower(cChar)
                EndIf
            EndIf
        EndIf
    Next

Return cRes
