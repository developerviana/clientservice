#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"

/*------------------------------------------------------------------------//
//Programa:  CADIMPORT
//Autor:     Victor 
//Descricao: Importação de Clientes via CSV para tabela SA1
//------------------------------------------------------------------------*/

User Function CADIMPORT()
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

    bConfirm := {|| FwMsgRun(,{|oSay| ImportaClientes(cPlanilha), NIL}, 'Processando Planilha ... ', "",) }
    bSair := {|| Iif(MsgYesNo('Você tem certeza que deseja sair da rotina?', 'Sair da rotina'), (oDialog:DeActivate()), NIL) }

    oDialog := FWDialogModal():New()

    oDialog:SetBackground(.T.)
    oDialog:SetTitle('Importação de Clientes via CSV')
    oDialog:SetSize(140, 250) 
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
    cTexto += "• O Layout deverá seguir o número exato de colunas (12)<br>"
    cTexto += "• O Arquivo não deve conter ';' em suas descrições<br>"
    cTexto += "• Colunas: CODIGO;LOJA;NOME;NOMEREDUZIDO;TIPO;PESSOA;CNPJCPF;INSCRESTADUAL;CEP;ENDERECO;BAIRRO;CIDADE;UF;TELEFONE;EMAIL<br>"

    oSay2 := TSay():New(005,010,{||cTexto},oContainer,,,,,,.T.,,,900,40)

    oSay1 := TSay():New(055,010,{||'Arquivo CSV:'},oContainer,,,,,,.T.,,,100,9)
    oTGet0 := tGet():New(065,010,{|u| if(PCount()>0,cPlanilha:=u,cPlanilha)},oContainer ,180,9,"",,,,,,,.T.,,, {|| .T. } ,,,,.F.,,,"cPlanilha")

    oTButton1 := TButton():New(080, 010, "Selecionar..." ,oContainer,{|| (cPlanilha:=cGetFile("Arquivos CSV | *.csv",OemToAnsi("Selecione o arquivo CSV"),,"",.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.F.)), } , 100,10,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDialog:Activate()
Return

Static Function ImportaClientes(cArquivo)
    Local aHeaderEsperado := {"CODIGO", "LOJA", "NOME", "NOMEREDUZIDO", "TIPO", "PESSOA", "CNPJCPF", "INSCRESTADUAL", "CEP", "ENDERECO", "BAIRRO", "CIDADE", "UF", "TELEFONE", "EMAIL"}
    Local aHeaderLido := {}
    Local lHeaderValido := .T.
    Local nIncluidos := 0, nAtualizados := 0, nIgnorados := 0, nErros := 0
    Local cLinha, aCampos, cChave
    Local oArquivo
    Local aLinhas := {}
    Local nTotLinhas := 0
    Local nLinha := 0
    Local nI := 0
    Local lExiste := .F.
    Local cLog := ""

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
        FWAlertError("Cabeçalho inválido. Esperado: " + ArrayToStr(aHeaderEsperado, ";"), "Erro")
        Return
    EndIf

    // Abertura da tabela SA1
    DbSelectArea("SA1")
    SA1->(DbSetOrder(1)) // A1_FILIAL + A1_COD + A1_LOJA

    // Processamento das linhas a partir da linha 02
    ProcRegua(nTotLinhas - 1)
    
    For nLinha := 2 To nTotLinhas
        IncProc("Processando linha: " + Str(nLinha))
        cLinha := AllTrim(aLinhas[nLinha])

        If Empty(cLinha)
            Loop
        EndIf

        aCampos := StrTokArr(cLinha, ";")

        If Len(aCampos) != Len(aHeaderEsperado)
            cLog += "Linha " + Str(nLinha) + ": Número incorreto de colunas (" + Str(Len(aCampos)) + " encontradas, " + Str(Len(aHeaderEsperado)) + " esperadas)" + CRLF
            nIgnorados++
            Loop
        EndIf

        // Validações básicas
        If Empty(AllTrim(aCampos[1])) .Or. Empty(AllTrim(aCampos[2])) .Or. Empty(AllTrim(aCampos[3]))
            cLog += "Linha " + Str(nLinha) + ": Código, Loja ou Nome não informados" + CRLF
            nIgnorados++
            Loop
        EndIf

        cChave := xFilial("SA1") + PadR(AllTrim(aCampos[1]), TamSX3("A1_COD")[1]) + ;
                  PadR(AllTrim(aCampos[2]), TamSX3("A1_LOJA")[1])

        lExiste := SA1->(DbSeek(cChave))

        If lExiste
            // Atualizar registro existente
            If RecLock("SA1", .F.)
                SA1->A1_NOME    := AllTrim(aCampos[3])
                SA1->A1_NREDUZ  := AllTrim(aCampos[4])
                SA1->A1_TIPO    := AllTrim(aCampos[5])
                SA1->A1_PESSOA  := AllTrim(aCampos[6])
                SA1->A1_CGC     := OnlyNumber(AllTrim(aCampos[7]))
                SA1->A1_INSCR   := AllTrim(aCampos[8])
                SA1->A1_CEP     := OnlyNumber(AllTrim(aCampos[9]))
                SA1->A1_END     := AllTrim(aCampos[10])
                SA1->A1_BAIRRO  := AllTrim(aCampos[11])
                SA1->A1_MUN     := AllTrim(aCampos[12])
                SA1->A1_EST     := AllTrim(aCampos[13])
                SA1->A1_TEL     := AllTrim(aCampos[14])
                SA1->A1_EMAIL   := AllTrim(aCampos[15])
                MsUnlock()
                nAtualizados++
                cLog += "Linha " + Str(nLinha) + ": Cliente " + AllTrim(aCampos[1]) + "-" + AllTrim(aCampos[2]) + " atualizado com sucesso" + CRLF
            Else
                cLog += "Linha " + Str(nLinha) + ": Erro ao dar lock no cliente " + AllTrim(aCampos[1]) + "-" + AllTrim(aCampos[2]) + CRLF
                nErros++
            EndIf
        Else
            // Incluir novo registro
            If RecLock("SA1", .T.)
                SA1->A1_FILIAL  := xFilial("SA1")
                SA1->A1_COD     := AllTrim(aCampos[1])
                SA1->A1_LOJA    := AllTrim(aCampos[2])
                SA1->A1_NOME    := AllTrim(aCampos[3])
                SA1->A1_NREDUZ  := AllTrim(aCampos[4])
                SA1->A1_TIPO    := AllTrim(aCampos[5])
                SA1->A1_PESSOA  := AllTrim(aCampos[6])
                SA1->A1_CGC     := OnlyNumber(AllTrim(aCampos[7]))
                SA1->A1_INSCR   := AllTrim(aCampos[8])
                SA1->A1_CEP     := OnlyNumber(AllTrim(aCampos[9]))
                SA1->A1_END     := AllTrim(aCampos[10])
                SA1->A1_BAIRRO  := AllTrim(aCampos[11])
                SA1->A1_MUN     := AllTrim(aCampos[12])
                SA1->A1_EST     := AllTrim(aCampos[13])
                SA1->A1_TEL     := AllTrim(aCampos[14])
                SA1->A1_EMAIL   := AllTrim(aCampos[15])

                MsUnlock()
                nIncluidos++
                cLog += "Linha " + Str(nLinha) + ": Cliente " + AllTrim(aCampos[1]) + "-" + AllTrim(aCampos[2]) + " incluído com sucesso" + CRLF
            Else
                cLog += "Linha " + Str(nLinha) + ": Erro ao incluir cliente " + AllTrim(aCampos[1]) + "-" + AllTrim(aCampos[2]) + CRLF
                nErros++
            EndIf
        EndIf
    Next

    // Salvar log em arquivo
    If !Empty(cLog)
        SalvaLogImportacao(cLog)
    EndIf

    // Exibir resumo
    FWAlertInfo("Importação finalizada!" + CRLF + ;
                "Incluídos: " + Str(nIncluidos) + CRLF + ;
                "Atualizados: " + Str(nAtualizados) + CRLF + ;
                "Ignorados: " + Str(nIgnorados) + CRLF + ;
                "Erros: " + Str(nErros), "Resumo da Importação")

    ConOut("[CADIMPORT] Importação finalizada - Incluídos: " + Str(nIncluidos) + " | Atualizados: " + Str(nAtualizados) + " | Ignorados: " + Str(nIgnorados) + " | Erros: " + Str(nErros))
Return

Static Function SalvaLogImportacao(cLog)
    Local cArquivoLog := "\temp\importacao_clientes_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".log"
    Local nHandle

    nHandle := FCreate(cArquivoLog)
    If nHandle > 0
        FWrite(nHandle, "LOG DE IMPORTACAO DE CLIENTES - " + DToC(Date()) + " " + Time() + CRLF + CRLF)
        FWrite(nHandle, cLog)
        FClose(nHandle)
        ConOut("[CADIMPORT] Log salvo em: " + cArquivoLog)
    Else
        ConOut("[CADIMPORT] Erro ao criar arquivo de log: " + cArquivoLog)
    EndIf
Return

Static Function OnlyNumber(cTexto)
    Local cResult := ""
    Local nI

    For nI := 1 To Len(cTexto)
        If IsDigit(SubStr(cTexto, nI, 1))
            cResult += SubStr(cTexto, nI, 1)
        EndIf
    Next

Return cResult
