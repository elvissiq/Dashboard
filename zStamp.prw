//Bibliotecas
#Include "TOTVS.ch"
 
/*/{Protheus.doc} zStamp
Criação de campos S_T_A_M_P_ e I_N_S_D_T
@type user function
@author Elvis Siqueira (TOTVS PE/AL)
@since 06/05/2026
@example
u_zStamp() 
/*/

User Function zStamp()

    FWMsgRun(, {|oSay| zCriaRows(oSay) }, "Processando", "Buscando as tabelas")

Return

Static Function zCriaRows(oSay)
Local aTabelas  := {}
Local lStamp    := .T.
Local lInsDt    := .T.
Local lOkStamp  := .F.
Local lOkInsDt  := .F.
Local nFor      := 0

    aTabelas := {   "SA2", "SA5", "SY1", "SAH", "SC1","SB1", "SBM", "NNR", "SB5", "SAH", "SBF","SA1", "SF4", "SE4", "SA3", "SX5","SA6", "SED", "SEB", "SEC", "SEE",;
                    "CT1", "CTH", "CTJ", "CTM", "CTL","SF4", "SFB", "SFA", "SYD", "SFE","SLB", "SLR", "SLV", "ST9", "SLG","SN1", "SN2", "SN0", "SNG","CN1","CNB",;
                    "CNC", "CND","SH1", "SG1", "SH3", "SH4", "SHB";
                }

	For nFor := 1 To Len(aTabelas)
        
        oSay:SetText("Tabela " + cValToChar(nFor) + " de " + cValToChar(Len(aTabelas)))

        IF &(aTabelas[nFor])->(FieldPos("S_T_A_M_P_")) <= 0

            dbSelectArea(aTabelas[nFor])
            
            //Valida se consegue ativar o recurso no BD
            lOkStamp    := (lStamp .And. (TCConfig('SETAUTOSTAMP = ON') == 'OK') .And. (TCConfig('SETUSEROWSTAMP = ON') == 'OK'))
            lOkInsDt    := (lInsDt .And. (TCConfig('SETAUTOINSDT = ON') == 'OK') .And. (TCConfig('SETUSEROWINSDT = ON') == 'OK'))
            If lOkStamp .Or. lOkInsDt
        
                //Busca o nome real da tabela, exemplo SB1 => SB1010
                cTabSQL := RetSQLName(aTabelas[nFor])
            
                //Se a tabela já estiver aberta, fecha para depois abrir em modo exclusivo
                If Select(aTabelas[nFor]) > 0
                    (aTabelas[nFor])->(DbCloseArea())
                EndIf
            
                //Tenta Abrir em modo Exclusivo
                USE (cTabSQL) ALIAS (aTabelas[nFor]) EXCLUSIVE NEW VIA "TOPCONN"
                If ! NetErr()
            
                    //Aciona o Refresh na tabela
                    TCRefresh(cTabSQL)
            
                Else
                    FWAlertError('Tabela "' + aTabelas[nFor] + '" - não foi possível abrir em modo Exclusivo', 'Falha #1')
                EndIf
        
                //Desativa os recursos
                TCConfig('SETAUTOSTAMP = OFF')
                TCConfig('SETUSEROWSTAMP = OFF')
        
            //Senão, não será possível criar os campos
            Else
                FWAlertError('Não foi possível ativar os recursos no BD', 'Falha #2')
            EndIf
        EndIF

	Next nFor
 
Return
