//Bibliotecas
#Include "TOTVS.ch"
 
/*/{Protheus.doc} zStamp
Criação de campos S_T_A_M_P_ e I_N_S_D_T
@type user function
@author Atilio
@since 23/12/2024
@param cTabAlias, Caractere, Alias da tabela (exemplo SB1)
@param lStamp, Lógico, Se .T. tenta criar o campo S_T_A_M_P_
@param lInsDt, Lógico, Se .T. tenta criar o campo I_N_S_D_T_
@example
u_zStamp("SB1")
@obs Foi construído essa função baseado no comentário do Sangar Zucchi nesse link: https://terminaldeinformacao.com/2023/01/25/para-que-serve-os-novos-campos-s_t_a_m_p_-e-i_n_s_d_t_-e-como-utiliza-los-no-protheus/
 
/*/

User Function zStamp()

    FWMsgRun(, {|oSay| zCriaRows(oSay,Nil,Nil,Nil) }, "Processando", "Buscando as tabelas")

Return

Static Function zCriaRows(oSay,cTabAlias,lStamp,lInsDt)
Local cTabSQL     := ""
Local cQry        := ""
Local _cAlias     := FWTimeStamp()
Local lOkStamp    := .F.
Local lOkInsDt    := .F.
Local nAtual      := 0
Local nTotal      := 0

Default cTabAlias := ""
Default lStamp    := .T.
Default lInsDt    := .T.
 
    //Se veio algum alias e ele existir na base
    cQry := "SELECT X2_CHAVE FROM " + RetSQLName('SX2') + " WHERE D_E_L_E_T_ <> '*'"
	PlsQuery(cQry, _cAlias)
    DbSelectArea(_cAlias)
    Count to nTotal

    (_cAlias)->(DbGoTop())

	While ! (_cAlias)->(Eof())
        
        nAtual++
        oSay:SetText("Tabela " + cValToChar(nAtual) + " de " + cValToChar(nTotal))

        cTabAlias := (_cAlias)->X2_CHAVE
        
        IF TCSqlExec("SELECT * FROM " + RetSQLName(cTabAlias)) >= 0
            //Valida se consegue ativar o recurso no BD
            lOkStamp    := (lStamp .And. (TCConfig('SETAUTOSTAMP = ON') == 'OK') .And. (TCConfig('SETUSEROWSTAMP = ON') == 'OK'))
            lOkInsDt    := (lInsDt .And. (TCConfig('SETAUTOINSDT = ON') == 'OK') .And. (TCConfig('SETUSEROWINSDT = ON') == 'OK'))
            If lOkStamp .Or. lOkInsDt
    
                //Busca o nome real da tabela, exemplo SB1 => SB1010
                cTabSQL := RetSQLName(cTabAlias)
    
                //Se a tabela já estiver aberta, fecha para depois abrir em modo exclusivo
                If Select(cTabAlias) > 0
                    (cTabAlias)->(DbCloseArea())
                EndIf
    
                //Tenta Abrir em modo Exclusivo
                USE (cTabSQL) ALIAS (cTabAlias) EXCLUSIVE NEW VIA "TOPCONN"
                If ! NetErr()
    
                    //Aciona o Refresh na tabela
                    TCRefresh(cTabSQL)
    
                Else
                    FWAlertError('Tabela "' + cTabAlias + '" - não foi possível abrir em modo Exclusivo', 'Falha #1')
                EndIf
                (cTabAlias)->(DbCloseArea())
    
                //Desativa os recursos
                TCConfig('SETAUTOSTAMP = OFF')
                TCConfig('SETUSEROWSTAMP = OFF')
    
            //Senão, não será possível criar os campos
            Else
                FWAlertError('Não foi possível ativar os recursos no BD', 'Falha #2')
            EndIf
        EndIF
	(_cAlias)->(DbSkip())
	End
	(_cAlias)->(DbCloseArea())
 
Return
