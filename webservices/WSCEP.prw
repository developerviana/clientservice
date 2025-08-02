#Include 'Protheus.ch'
#Include 'RestFul.ch'

WSRESTFUL WSCEP DESCRIPTION "Consulta CEP usando ViaCEP"
WSMETHOD GET DESCRIPTION "Consulta dados do endereço via ViaCEP" WSSYNTAX "/WSCEP/{CEP}"
END WSRESTFUL

WSMETHOD GET WSSERVICE WSCEP
    Local aArea := GetArea()
    Local cCEP := ""
    Local cUrl := ""
    Local oHttp := Nil
    Local oJson := Nil
    Local oResp := Nil
    Local cRetorno := ""

    ::SetContentType("application/json")

    If Len(::aURLParms) > 0
        cCEP := AllTrim(StrTran(::aURLParms[1], "-", ""))
        cUrl := "https://viacep.com.br/ws/" + cCEP + "/json/"
        oHttp := FWRest():New(cUrl)

        If oHttp:Get()
            oJson := JsonObject():New(oHttp:GetResult())
            oResp := oJson:GetJsonObject()

            If !Empty(oResp["erro"])
                ::SetResponse('{"erro":"CEP não encontrado"}')
            Else
                cRetorno := FWJsonSerialize( oResp, .T., .T. )
                ::SetResponse(cRetorno)
            EndIf
        Else
            ::SetResponse('{"erro":"Erro na chamada ao ViaCEP"}')
        EndIf
    Else
        ::SetResponse('{"erro":"CEP não informado"}')
    EndIf

    RestArea(aArea)
Return .T.
