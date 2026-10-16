@echo off
rem =====================================================================
rem  LLAMA LAUNCHER 2.1  -  OpenCode Ready  (GitHub Edition v1.3)
rem ---------------------------------------------------------------------
rem  Una sola ventana para lanzar modelos llama.cpp en CPU con soporte
rem  para OpenCode:
rem    [1] GGUF / llama-server (llama.cpp) -> servidor OpenAI-compatible
rem    [2] Multimodal LLM (GGUF o HuggingFace)
rem
rem  Compatible con arrastrar-y-soltar (drag & drop) de un .txt de config.
rem  Licencia MIT - ver LICENSE.
rem =====================================================================
setlocal EnableDelayedExpansion
chcp 65001 >nul

cd /d "%~dp0"

rem Fecha actual (para el banner y los archivos generados)
for /f "tokens=*" %%F in ('date /t') do set "CurrentDate=%%F"

rem ---- Argumento por arrastrar-y-soltar: solo .txt ----------------
if "%~1"=="" goto MainMenu
if /i not "%~x1"==".txt" goto InvalidExtensionTXT

rem Leemos secuencialmente las 6 lineas del archivo de configuracion
set "ModelPath="
set "ContextSize="
set "HostAddress="
set "MmprojPath="
set "JinjaMode="
set "ChatTemplateFile="
<"%~1" (
    set /p ModelPath=
    set /p ContextSize=
    set /p HostAddress=
    set /p MmprojPath=
    set /p JinjaMode=
    set /p ChatTemplateFile=
)
if "!ContextSize!"=="" set "ContextSize=0"
if "!HostAddress!"=="" set "HostAddress=127.0.0.1"
if "!JinjaMode!"=="" set "JinjaMode=Y"

echo [OK] Configuracion cargada desde "%~nx1"
goto ProcessInput

:InvalidExtensionTXT
echo [ERROR] Extension de archivo invalida. Solo se admiten archivos .txt
echo         para arrastrar y soltar.
goto End

rem =====================================================================
rem  MENU PRINCIPAL
rem =====================================================================
:MainMenu
echo.
echo =====================================================
echo    LLAMA LAUNCHER 2.1 - OpenCode Ready
echo =====================================================
echo   Fecha: !CurrentDate!
echo -----------------------------------------------------
echo   [1]  GGUF / llama-server   (llama.cpp, CPU)
echo   [2]  Multimodal LLM      (GGUF o HuggingFace)
echo =====================================================
set "LaunchMode="
set /p "LaunchMode=Selecciona modo (1 o 2): "
if "!LaunchMode!"=="1" goto PromptDragDrop
if "!LaunchMode!"=="2" goto MMMode
echo [ERROR] Opcion invalida. Escribe 1 o 2.
goto MainMenu

rem =====================================================================
rem  MODO 2 - MULTIMODAL
rem =====================================================================
:MMMode
echo.
echo --- Inferencia multimodal ---
echo.
set "MModelPath="
set /p "MModelPath=Ruta del modelo (.gguf O carpeta HuggingFace): "
if not "!MModelPath!"=="" set "MModelPath=!MModelPath:"=!"
if "!MModelPath!"=="" (
    echo [INFO] No se indico ruta. Volviendo al menu.
    goto MainMenu
)
rem Ruta: .gguf -> llama-mtmd-cli.exe  |  carpeta -> Python transformers
if /i "!MModelPath:~-5!"==".gguf" goto MMGGUF
if exist "!MModelPath!\" goto MMHuggingFace
echo.
echo [ERROR] Ruta no encontrada o formato no reconocido.
echo    - Modelo GGUF  : apunta a un archivo .gguf  (usa llama-mtmd-cli.exe)
echo    - HuggingFace  : apunta a la carpeta del modelo (usa Python transformers)
goto End

:MMGGUF
echo [GGUF] Usando llama-mtmd-cli.exe
echo.
if not exist "%~dp0llama-mtmd-cli.exe" (
    echo [ERROR] No se encontro llama-mtmd-cli.exe en esta carpeta.
    echo         Asegurate de usar una build reciente de llama.cpp.
    goto End
)
set "MMmprojPath="
set /p "MMmprojPath=Ruta del mmproj GGUF (o Enter para omitir): "
if not "!MMmprojPath!"=="" set "MMmprojPath=!MMmprojPath:"=!"
set "MImagePath="
set /p "MImagePath=Ruta de la imagen (o Enter para omitir): "
if not "!MImagePath!"=="" set "MImagePath=!MImagePath:"=!"
echo.
set "MPrompt=Describe what you see"
set /p "MPrompt=Prompt [default: Describe what you see]: "
if "!MPrompt!"=="" set "MPrompt=Describe what you see"
echo.
echo Ejecutando inferencia multimodal GGUF (modo CPU)...
if "!MMmprojPath!"=="" (
    if "!MImagePath!"=="" (
        llama-mtmd-cli.exe -m "!MModelPath!" -c 0 -p "!MPrompt!"
    ) else (
        llama-mtmd-cli.exe -m "!MModelPath!" -c 0 -p "!MPrompt!" --image "!MImagePath!"
    )
) else (
    if "!MImagePath!"=="" (
        llama-mtmd-cli.exe -m "!MModelPath!" --mmproj "!MMmprojPath!" -c 0 -p "!MPrompt!"
    ) else (
        llama-mtmd-cli.exe -m "!MModelPath!" --mmproj "!MMmprojPath!" -c 0 -p "!MPrompt!" --image "!MImagePath!"
    )
)
goto End

:MMHuggingFace
echo [HuggingFace] Usando Python transformers
echo.
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No se encontro Python. Instala Python 3.10+ y anadelo al PATH.
    goto End
)
python -c "import torch" >nul 2>&1
if errorlevel 1 (
    echo [INFO] torch no instalado. Instalando paquetes requeridos (tarda un rato)...
    python -m pip install torch transformers pillow soundfile accelerate
    if errorlevel 1 (
        echo.
        echo [ERROR] Fallo la instalacion. Ejecuta manualmente y reintenta:
        echo    pip install torch transformers pillow soundfile accelerate
        goto End
    )
)
set "MImagePath="
set /p "MImagePath=Ruta de la imagen (o Enter para omitir): "
if not "!MImagePath!"=="" set "MImagePath=!MImagePath:"=!"
echo.
set "MPrompt="
set /p "MPrompt=Prompt (o Enter para modo interactivo): "
if not "!MPrompt!"=="" set "MPrompt=!MPrompt:"=!"
echo.
echo Ejecutando inferencia multimodal HuggingFace...
if "!MImagePath!"=="" (
    if "!MPrompt!"=="" (
        python "%~dp0inference_helper.py" --model "!MModelPath!"
    ) else (
        python "%~dp0inference_helper.py" --model "!MModelPath!" --prompt "!MPrompt!"
    )
) else (
    if "!MPrompt!"=="" (
        python "%~dp0inference_helper.py" --model "!MModelPath!" --image "!MImagePath!"
    ) else (
        python "%~dp0inference_helper.py" --model "!MModelPath!" --image "!MImagePath!" --prompt "!MPrompt!"
    )
)
goto End

rem =====================================================================
rem  MODO 1 - SERVIDOR llama-server (OpenCode)
rem =====================================================================
:PromptDragDrop
echo.
echo Arrastra y suelta aqui el modelo (.gguf, .bin, .ggml):
set "InputPath="
set /p "InputPath="
set "ModelPath=!InputPath!"
if not "!ModelPath!"=="" set "ModelPath=!ModelPath:"=!"

if /i "!ModelPath:~-5!"==".gguf" goto ValidModel
if /i "!ModelPath:~-4!"==".bin" goto ValidModel
if /i "!ModelPath:~-5!"==".ggml" goto ValidModel

echo [ERROR] Extension de archivo invalida.
echo.
goto PromptDragDrop

:ValidModel
if not exist "!ModelPath!" (
    echo [ERROR] No se encontro el archivo: "!ModelPath!"
    goto End
)
echo [OK] Archivo de modelo aceptado: "!ModelPath!"

:PromptMultimodal
echo.
echo Es un modelo multimodal (p.ej. LLaVA, Qwen-VL)? Tienes un mmproj? (Y/N)
set "MultimodalChoice="
set /p "MultimodalChoice="
if /i "!MultimodalChoice!"=="Y" goto PromptMmproj
set "MmprojPath="
goto PromptChatFormat

:PromptMmproj
echo.
echo Ruta completa del archivo mmproj .gguf (o arrastralo aqui):
set "MmprojPath="
set /p "MmprojPath="
if not "!MmprojPath!"=="" set "MmprojPath=!MmprojPath:"=!"
if "!MmprojPath!"=="" echo [INFO] Sin mmproj. Soporte multimodal desactivado.
if not "!MmprojPath!"=="" echo [OK] Mmproj: "!MmprojPath!"


:PromptChatFormat
echo.
echo Es un modelo instruct/chat (termina en "-it", "-Instruct", etc.)?
echo Habilita plantillas Jinja nativas: necesario para tool-calling y para
echo que el streaming no se corte al conectar con OpenCode. (Y/N)
set "JinjaMode="
set /p "JinjaMode=Habilitar modo Instruct/Jinja [default: Y]: "
if "!JinjaMode!"=="" set "JinjaMode=Y"
set "ChatTemplateFile="
if /i not "!JinjaMode!"=="Y" goto PromptContextSize
echo.
echo Si el GGUF trae una plantilla de chat defectuosa (comun en algunos .it),
echo puedes indicar aqui un archivo .jinja alternativo. Deja vacio para usar
echo la plantilla incluida en el modelo.
set /p "ChatTemplateFile=Ruta a chat-template .jinja (opcional): "
if not "!ChatTemplateFile!"=="" set "ChatTemplateFile=!ChatTemplateFile:"=!"

:PromptContextSize
echo.
echo Tamano de contexto (0 = auto-deteccion desde el GGUF, o un valor fijo):
set "ContextSize="
set /p "ContextSize=Contexto [default: 0]: "
if "!ContextSize!"=="" set "ContextSize=0"
echo Contexto fijado en: !ContextSize!

:PromptNetwork
echo.
echo Quieres permitir acceso desde otros dispositivos de tu red WiFi? (Y/N)
set "HostChoice="
set /p "HostChoice="

if /i "!HostChoice!"=="Y" goto NetworkEnabled
set "HostAddress=127.0.0.1"
echo Acceso de red: DESACTIVADO (solo PC local).
goto SavePreset

:NetworkEnabled
set "HostAddress=0.0.0.0"
echo Acceso de red: ACTIVADO.
echo.
echo --- PARA CONECTAR DESDE TU MOVIL / OTRO PC ---
echo Abre tu navegador y entra a una de estas direcciones IPv4 seguidas de :8080
echo Ejemplo: http://192.168.1.5:8080
echo Tus direcciones IPv4 actuales son:
ipconfig | findstr /i "IPv4"
echo ---------------------------------------------

:SavePreset
echo(!ModelPath!>last_launch.txt
echo(!ContextSize!>> last_launch.txt
echo(!HostAddress!>> last_launch.txt
echo(!MmprojPath!>> last_launch.txt
echo(!JinjaMode!>> last_launch.txt
echo(!ChatTemplateFile!>> last_launch.txt

:ProcessInput
for %%A in ("!ModelPath!") do set "AliasName=%%~nA"
echo.
echo --- PARAMETROS DE LANZAMIENTO ---
echo Modelo:   !ModelPath!
echo Alias:    !AliasName!
echo Contexto: !ContextSize!
echo Host:     !HostAddress!
echo Puerto:   8080
if not "!MmprojPath!"=="" echo Mmproj:   !MmprojPath!
echo Jinja/Tool-calling: !JinjaMode!
if not "!ChatTemplateFile!"=="" echo Chat template: !ChatTemplateFile!
echo --------------------------
if "!ContextSize!"=="0" (
    echo.
    echo NOTA: Contexto 0 = auto-detectado desde el GGUF. En modelos con
    echo ventanas de entrenamiento muy grandes ^(128k o mas^), esto puede
    echo disparar el uso de RAM y volver la generacion en CPU tan lenta
    echo que parece que el streaming "se congela" o se pierde.
    echo Si te pasa, relanza y fija un valor fijo, ej. 8192 o 16384.
)
echo.
echo --- CONFIGURACION PARA OPENCODE ---
(
echo {
echo   "$schema": "https://opencode.ai/config.json",
echo   "provider": {
echo     "llamacpp": {
echo       "npm": "@ai-sdk/openai-compatible",
echo       "name": "llama.cpp (local)",
echo       "options": { "baseURL": "http://127.0.0.1:8080/v1" },
echo       "models": { "!AliasName!": { "name": "!AliasName!" } }
echo     }
echo   }
echo }
) > "%~dp0opencode.json"
echo Archivo creado/actualizado: %~dp0opencode.json
echo Si tu proyecto de OpenCode vive en otra carpeta, copia ese archivo ahi,
echo o fusiona el bloque "provider" dentro de tu opencode.json existente
echo ^(o en %%USERPROFILE%%\.config\opencode\opencode.json para dejarlo global^).
echo ------------------------------------
echo.

rem Verificacion del ejecutable del servidor
if exist "llama-server.exe" goto StartServer
echo [ERROR] No se encontro llama-server.exe en esta carpeta:
echo %~dp0
echo Descargalo desde https://github.com/ggml-org/llama.cpp/releases
goto End

:StartServer
echo Ejecutando servidor (modo CPU)... Pulsa Ctrl+C para detenerlo.
echo.
set "ExtraArgs="
if not "!MmprojPath!"=="" set "ExtraArgs=!ExtraArgs! --mmproj "!MmprojPath!""
if /i "!JinjaMode!"=="Y" set "ExtraArgs=!ExtraArgs! --jinja"
if not "!ChatTemplateFile!"=="" set "ExtraArgs=!ExtraArgs! --chat-template "!ChatTemplateFile!""

echo Iniciando servidor con soporte de plantillas Jinja para Tool-Calling...
llama-server.exe -m "!ModelPath!" -c !ContextSize! --flash-attn auto -ngl 0 --host !HostAddress! --port 8080 --alias "!AliasName!" !ExtraArgs!

rem Manejo de errores plano
if errorlevel 1 goto ServerError
echo.
echo Servidor detenido correctamente.
goto End

:ServerError
echo.
echo [ERROR] El servidor termino con un error.
goto End

:End
endlocal
echo.
echo Script finalizado.
pause

