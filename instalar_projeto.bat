@echo off
setlocal enabledelayedexpansion
title Instalador Dashboard - @elvissiq

:: --- CONFIGURAÇÃO ---
set "REPO_API=https://api.github.com/repos/elvissiq/Dashboard/commits/main"
set "URL_BASE_RAW=https://raw.githubusercontent.com/elvissiq/Dashboard"
set "URL_ICONE=https://raw.githubusercontent.com/elvissiq/Dashboard/main/icon.ico"
set "DESTINO=C:\Dashboard"
set "PYTHON_PATH=C:\Program Files\Python313\python.exe"

:: --- VERIFICAR ADMINISTRADOR ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ############################################################
    echo ERRO: VOCE PRECISA EXECUTAR COMO ADMINISTRADOR.
    echo ############################################################
    pause
    exit /b
)

if not exist "%DESTINO%" mkdir "%DESTINO%"

echo [+] Baixando icone...
curl -L -s -o "%DESTINO%\icon.ico" "%URL_ICONE%"

echo [+] Verificando Python 3.13...
if not exist "%PYTHON_PATH%" (
    echo [+] Instalando Python...
    winget install --id Python.Python.3.13 --scope machine --exact --accept-package-agreements --accept-source-agreements
)

echo [+] Instalando bibliotecas...
"%PYTHON_PATH%" -m pip install --upgrade pip
"%PYTHON_PATH%" -m pip install streamlit requests pandas plotly

echo [+] Criando motor de execucao (Force Commit Sync)...

:: Criando o run_dashboard.bat linha por linha
echo @echo off > "%DESTINO%\run_dashboard.bat"
echo title Servidor_Dashboard >> "%DESTINO%\run_dashboard.bat"
echo cd /d "%DESTINO%" >> "%DESTINO%\run_dashboard.bat"
echo. >> "%DESTINO%\run_dashboard.bat"
echo echo [+] Verificando ultima versao real no GitHub... >> "%DESTINO%\run_dashboard.bat"
echo. >> "%DESTINO%\run_dashboard.bat"
echo :: Obtem o HASH do ultimo commit para ignorar 100%% do cache de rede >> "%DESTINO%\run_dashboard.bat"
echo for /f "delims=" %%%%a in ('powershell -Command "$json = Invoke-RestMethod -Uri '%REPO_API%' -Headers @{'Cache-Control'='no-cache'}; $json.sha"') do set "SHA=%%%%a" >> "%DESTINO%\run_dashboard.bat"
echo. >> "%DESTINO%\run_dashboard.bat"
echo if "%%SHA%%" == "" ( >> "%DESTINO%\run_dashboard.bat"
echo    echo [!] Nao foi possivel obter o ID da versao. Usando versao local. >> "%DESTINO%\run_dashboard.bat"
echo ) else ( >> "%DESTINO%\run_dashboard.bat"
echo    echo [+] Versao detectada: %%SHA%% >> "%DESTINO%\run_dashboard.bat"
echo    echo [+] Baixando arquivo... >> "%DESTINO%\run_dashboard.bat"
echo    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%URL_BASE_RAW%/%%SHA%%/app.py', 'app_new.py')" >> "%DESTINO%\run_dashboard.bat"
echo    if exist "app_new.py" ( >> "%DESTINO%\run_dashboard.bat"
echo       del /f /q "app.py" ^>nul 2^>nul >> "%DESTINO%\run_dashboard.bat"
echo       ren "app_new.py" "app.py" >> "%DESTINO%\run_dashboard.bat"
echo    ) >> "%DESTINO%\run_dashboard.bat"
echo ) >> "%DESTINO%\run_dashboard.bat"
echo. >> "%DESTINO%\run_dashboard.bat"
echo echo [+] Iniciando Dashboard... >> "%DESTINO%\run_dashboard.bat"
echo "%PYTHON_PATH%" -m streamlit run app.py >> "%DESTINO%\run_dashboard.bat"

echo [+] Criando atalho na Area de Trabalho...
set "NOME_ATALHO=Dashboard Controle de Uso"
set "LAUNCHER=%DESTINO%\run_dashboard.bat"

powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), '%NOME_ATALHO%.lnk')); $s.TargetPath = '%LAUNCHER%'; $s.WorkingDirectory = '%DESTINO%'; $s.IconLocation = '%DESTINO%\icon.ico'; $s.Save()"

echo.
echo ============================================================
echo    INSTALACAO CONCLUIDA COM SUCESSO!
echo ============================================================
timeout /t 3 >nul
exit