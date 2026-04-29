#include "Totvs.ch"
#include "Protheus.ch"
#Include "RESTFUL.CH"
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"
#Include "TopConn.ch"

/*/
Função zStampAPI
@param Recebe parâmetro Nil
@author Totvs Nordeste (Elvis Siqueira)
@since 28/04/2026
//zStampAPI - Web Service (REST)
Return
@project
@history
/*/

WSRestFul zStampAPI Description "Painel de Ordens" FORMAT APPLICATION_JSON

WSDATA company     AS CHARACTER OPTIONAL
WSDATA branch      AS CHARACTER OPTIONAL
WSDATA table       AS CHARACTER OPTIONAL
WSDATA data_inicio AS CHARACTER OPTIONAL
WSDATA data_fim    AS CHARACTER OPTIONAL

WSMethod GET Description "GET Entidades" WSSYNTAX "/api/retail/v1/zStampAPI" PATH "/api/retail/v1/zStampAPI"
End WSRestFul

WSMethod GET WSReceive Branch WSService zStampAPI
Local cMensag := {}
Local cQry    := ""
Local _cAlias := FWTimeStamp()
Local cNomTab := ""
Local cTabFil := ""

  /*
  If IsBlind()
    RpcClearEnv()
    RpcSetType(2) 
    RpcSetEnv(::company,::branch)
  EndIF */

  dbSelectArea('SX2')
  SX2->(dbSeek(::table))
  cNomTab := FWNoAccent(AllTrim(X2Nome()))

  cQry := "SELECT COUNT(*) as TOT_REG FROM " + RetSQLName(::table)
  cQry += " WHERE D_E_L_E_T_ <> '*' "
  If !Empty(::branch)
    cFilAnt := ::branch
    cTabFil := IIF(SubStr(::table,1,1)=="S",SubStr(::table,2,2),::table)
    cQry += "  AND " + cTabFil + "_FILIAL = '" + xFilial(::table) + "' "
  EndIF
  cQry += " AND S_T_A_M_P_ BETWEEN '" + DToS(CTOD(::data_inicio)) + " 00:00:00' AND '" + DToS(CTOD(::data_fim)) + " 23:59:59' "
	PlsQuery(cQry, _cAlias)
  DbSelectArea(_cAlias)

  If (_cAlias)->(!Eof())
    cMensag := '{ "quantidade": ' + cValToChar((_cAlias)->TOT_REG) + ', "nome": "' + cNomTab + '" }'
  EndIF 
  (_cAlias)->(DBCloseArea())

  ::SetContentType("application/json")
  ::SetResponse(cMensag)

  /*
  If IsBlind()
    RPCClearEnv()
  EndIF */

Return 
