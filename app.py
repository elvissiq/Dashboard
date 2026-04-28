import streamlit as st
import requests
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta

# 1. Configurações Iniciais da Página
st.set_page_config(
    page_title="Dashboard API Controle de Uso",
    page_icon="📊",
    layout="wide"
)

# ==============================================================================
# CONFIGURAÇÃO DOS MÓDULOS E TABELAS
# Preencha aqui os códigos das tabelas para cada módulo
# ==============================================================================
MAPA_MODULOS = {
    "Compras": ["SA2", "SA5", "SY1", "SAH"],
    "Estoque": ["SB1", "SBM", "NNR", "SB5", "SAH", "SBF"],
    "Faturamento": ["SA1", "SF4", "SE4", "SA3", "SX5"],
    "Financeiro": ["SA6", "SED", "SEB", "SEC", "SEE"],
    "Contábil": ["CT1", "CTH", "CTJ", "CTM", "CTL"],
    "Fiscal": ["SF4", "SFB", "SFA", "SYD", "SFE"],
    "Loja": ["SLB", "SLR", "SLV", "ST9", "SLG"],
    "Ativo Fixo": ["SN1", "SN2", "SN0", "SNG", "SNF"],
    "Gestão de Contratos": ["CN1", "CNB", "CNC", "CND"],
    "PCP": ["SH1", "SG1", "SH3", "SH4", "SHB"]
}
# ==============================================================================

st.title("📊 Controle de Uso")
st.markdown("---")

# 2. Barra Lateral
with st.sidebar:
    st.header("🔑 Configurações de Acesso_01")
    url_raiz = st.text_input("URL Raiz do Servidor", placeholder="https://IP:Porta/rest")
    
    col_user, col_pass = st.columns(2)
    with col_user:
        usuario = st.text_input("Usuário")
    with col_pass:
        senha = st.text_input("Senha", type="password")
    
    st.divider()
    st.header("📍 Localização e Período")
    col_empresa, col_filial = st.columns(2)
    with col_empresa:
        company = st.text_input("Empresa", placeholder="01")
    with col_filial:
        branch = st.text_input("Filial", placeholder="010101")

    d_padrao_inicio = datetime.now() - timedelta(days=7)
    col_data1, col_data2 = st.columns(2)
    with col_data1:
        data_inicio = st.date_input("De", d_padrao_inicio, format="DD/MM/YYYY")
    with col_data2:
        data_fim = st.date_input("Até", datetime.now(), format="DD/MM/YYYY")

    st.divider()
    st.header("📂 Seleção de Módulos")
    
    # Campo de Seleção de Módulos (Substituiu o Text Area)
    modulos_selecionados = st.multiselect(
        "Selecione um ou mais módulos:",
        options=list(MAPA_MODULOS.keys()),
        help="As tabelas serão carregadas automaticamente conforme o módulo selecionado."
    )
    
    st.divider()
    debug_mode = st.checkbox("Modo Debug (Ver JSON da API)")
    btn_gerar = st.button("🚀 Gerar Dashboard", type="primary", use_container_width=True)

# 3. Lógica de Processamento
if btn_gerar:
    if not url_raiz or not usuario or not senha or not modulos_selecionados:
        st.error("❌ Preencha os campos obrigatórios: URL, Usuário, Senha e selecione ao menos um Módulo.")
    elif data_inicio > data_fim:
        st.error("❌ A data 'De' não pode ser maior que 'Até'.")
    else:
        # CONSTRUÇÃO DA LISTA DE TABELAS BASEADO NOS MÓDULOS SELECIONADOS
        lista_tabelas = []
        for mod in modulos_selecionados:
            lista_tabelas.extend(MAPA_MODULOS[mod])
        
        # Remover duplicatas caso uma tabela esteja em dois módulos
        lista_tabelas = list(set(lista_tabelas))

        # Construção da URL
        raiz_limpa = url_raiz.strip().rstrip('/')
        endpoint_fixo = "/api/retail/v1/zStampAPI"
        url_completa = f"{raiz_limpa}{endpoint_fixo}"

        resultados = []
        str_inicio_br = data_inicio.strftime('%d/%m/%Y')
        str_fim_br = data_fim.strftime('%d/%m/%Y')

        progresso = st.progress(0)
        status_carregamento = st.empty()

        with st.spinner('Consultando API...'):
            for i, tabela_codigo in enumerate(lista_tabelas):
                progresso.progress((i + 1) / len(lista_tabelas))
                status_carregamento.text(f"Consultando {tabela_codigo}...")

                try:
                    params = {
                        "company": company, 
                        "branch": branch, 
                        "table": tabela_codigo,
                        "data_inicio": str_inicio_br, 
                        "data_fim": str_fim_br
                    }

                    response = requests.get(url_completa, params=params, auth=(usuario, senha), timeout=15)
                    
                    if response.status_code == 200:
                        dados_api = response.json()
                        
                        if debug_mode:
                            st.write(f"Debug {tabela_codigo}:", dados_api)

                        # Tratamento para extrair o NOME retornado pela API
                        if isinstance(dados_api, list) and len(dados_api) > 0:
                            dados_api = dados_api[0]

                        # Busca exaustiva pela tag de nome
                        api_nome = None
                        for chave in ['nome', 'Nome', 'NOME', 'description', 'desc']:
                            if chave in dados_api and dados_api[chave]:
                                api_nome = dados_api[chave]
                                break
                        
                        nome_exibicao = str(api_nome).strip() if api_nome else tabela_codigo
                        quantidade = dados_api.get("quantidade") or dados_api.get("total") or 0

                        resultados.append({
                            "Nome Visual": nome_exibicao, 
                            "Quantidade": int(quantidade),
                            "Código Original": tabela_codigo
                        })
                    
                    elif response.status_code == 401:
                        st.error("🔒 Acesso Negado: Verifique Usuário/Senha.")
                        break
                    else:
                        st.error(f"❌ Erro HTTP {response.status_code} na tabela {tabela_codigo}")
                
                except Exception as e:
                    st.error(f"🚨 Falha de rede: {str(e)}")
                    break

        progresso.empty()
        status_carregamento.empty()

        # 4. Exibição dos Resultados
        if resultados:
            df = pd.DataFrame(resultados)
            
            # Cards de métricas
            cols = st.columns(len(resultados))
            for idx, row in enumerate(resultados):
                with cols[idx]:
                    st.metric(
                        label=row["Nome Visual"], 
                        value=f"{row['Quantidade']:,}".replace(",", ".")
                    )

            st.divider()
            
            c1, c2 = st.columns([2, 1])
            with c1:
                st.write("### Comparativo de Uso")
                fig = px.bar(df, x='Nome Visual', y='Quantidade', color='Nome Visual', text_auto=True)
                st.plotly_chart(fig, use_container_width=True)
            
            with c2:
                st.write("### Detalhamento")
                st.dataframe(df[['Nome Visual', 'Quantidade']], use_container_width=True, hide_index=True)
            
            csv = df.to_csv(index=False).encode('utf-8')
            st.download_button("📥 Baixar CSV", csv, "relatorio_uso.csv", "text/csv", use_container_width=True)
        else:
            if not btn_gerar:
                st.info("Selecione os módulos e clique em Gerar.")
