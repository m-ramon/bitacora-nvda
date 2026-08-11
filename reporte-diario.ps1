# =====================================================================
#  Bitacora NVDA - corrida diaria automatica
#
#  Lo ejecuta el Programador de tareas de Windows los dias habiles
#  a las 17:35 (BYMA cierra 17:00).
#
#  Para probarlo a mano, desde PowerShell:
#     & "C:\Users\Usuario\Desktop\10_Finanzas\reporte-diario.ps1"
#
#  NOTA TECNICA: el prompt se le pasa a Claude por entrada estandar
#  (stdin), NO como argumento de linea de comandos. Si se pasa como
#  argumento, Windows lo parte en palabras sueltas y Claude recibe
#  solo la primera. Por el mismo motivo la lista de herramientas va
#  separada por comas y no por espacios.
# =====================================================================

$ErrorActionPreference = 'Stop'

# --- Ignorar CTRL+C --------------------------------------------------
# Al terminar, el proceso hijo dispara un evento de consola que mata a
# este script con STATUS_CONTROL_C_EXIT (0xC000013A) justo antes de
# escribir el log final. Con handler NULL y add=TRUE, este proceso
# ignora CTRL+C (comportamiento documentado de SetConsoleCtrlHandler).
try {
    $k32 = Add-Type -Namespace 'Win32Native' -Name 'ConsoleCtrl' -PassThru -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleCtrlHandler(IntPtr handlerRoutine, bool add);
'@
    [void]$k32::SetConsoleCtrlHandler([IntPtr]::Zero, $true)
}
catch {
    # Si falla no es fatal: el reporte se genera igual, se pierde el log final.
}

$Proyecto    = 'C:\Users\Usuario\Desktop\10_Finanzas'
$Logs        = Join-Path $Proyecto 'logs'
$Historial   = Join-Path $Proyecto 'historial.csv'
$PagesUrl    = 'https://m-ramon.github.io/bitacora-nvda/'
$TimeoutMin  = 12

# Que git no abra ningun dialogo de credenciales: si no tiene el token
# cacheado tiene que fallar rapido, no quedarse esperando a nadie.
$env:GIT_TERMINAL_PROMPT = '0'

if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs | Out-Null }

$hoy     = Get-Date -Format 'yyyy-MM-dd'
$logFile = Join-Path $Logs "$hoy.log"

function Log($msg) {
    $linea = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    Add-Content -Path $logFile -Value $linea -Encoding utf8
}

Log "=== Inicio de la corrida diaria ==="

# --- No correr los fines de semana -----------------------------------
$dia = (Get-Date).DayOfWeek
if ($dia -eq 'Saturday' -or $dia -eq 'Sunday') {
    Log "Fin de semana ($dia). BYMA no opera. No se genera reporte."
    exit 0
}

# --- Se salteo algun dia? --------------------------------------------
# El envoltorio a veces muere al final sin poder escribir el log (ver
# nota tecnica del README), asi que no se puede confiar en el log del
# dia para saber si anduvo. La prueba real es el CSV: si falta la fila
# de la rueda anterior, avisamos ACA, al principio de la corrida
# siguiente. Un dia perdido nunca pasa desapercibido mas de 24 horas.
if (Test-Path $Historial) {
    $fechas = Get-Content $Historial -Encoding utf8 |
              Select-Object -Skip 1 |
              Where-Object { $_ -match '^\d{4}-\d{2}-\d{2},' } |
              ForEach-Object { [datetime]($_ -split ',')[0] }

    if ($fechas) {
        $ultima = ($fechas | Sort-Object)[-1]

        # Rueda anterior: el dia habil previo a hoy.
        $previa = (Get-Date).Date.AddDays(-1)
        while ($previa.DayOfWeek -eq 'Saturday' -or $previa.DayOfWeek -eq 'Sunday') {
            $previa = $previa.AddDays(-1)
        }

        if ($ultima.Date -lt $previa) {
            $faltan = [int]($previa - $ultima.Date).TotalDays
            Log "AVISO: el ultimo registro es del $($ultima.ToString('yyyy-MM-dd')). Faltan ruedas (unos $faltan dias). Revisar si la compu estuvo apagada."
        }
    }
}

# --- Ya corrio hoy? --------------------------------------------------
# Solo se saltea si la fila de hoy ya es de CIERRE. Si quedo una fila
# intradiaria (de una corrida a mercado abierto), hay que reemplazarla
# por los datos del cierre.
$filaHoy = $null
if (Test-Path $Historial) {
    $filaHoy = Select-String -Path $Historial -Pattern "^$hoy," | Select-Object -First 1
}
if ($filaHoy -and $filaHoy.Line -match "^$hoy,[^,]*,cierre,") {
    Log "El historial ya tiene la fila de cierre de $hoy. No se vuelve a correr."
    exit 0
}
if ($filaHoy) {
    Log "Hay una fila intradiaria de $hoy. Se va a reemplazar por los datos del cierre."
}

# --- La instruccion para Claude --------------------------------------
# Deliberadamente corta: el detalle vive en README.md, asi se puede
# cambiar el procedimiento sin tocar este script.
$prompt = @"
Ejecuta el reporte diario de la bitacora NVDA.

1. Lee $Proyecto\README.md y segui la seccion 'Procedimiento diario' al pie de la letra.
2. Lee tambien posicion.json y las ultimas filas de historial.csv para tener el contexto.
3. El tablero es index.html. Es un documento HTML COMPLETO (doctype, head con charset y
   viewport). Al regenerarlo NO le saques el esqueleto: sin el, el celular de Francisco lo
   muestra diminuto y se rompen los acentos.
4. Si hoy BYMA no opero (feriado), NO agregues fila al CSV ni toques index.html: explica por
   que y termina.
5. Si algun precio no se consigue, no lo estimes ni lo copies del dia anterior. Deja el
   campo vacio y decilo en la nota del dia.
6. Si historial.csv YA tiene una fila de hoy con estado 'intradiario', REEMPLAZALA por los
   datos del cierre (estado 'cierre'). No agregues una fila duplicada para el mismo dia.

7. PUBLICAR. Cuando el reporte este listo, hace commit y push con Bash:

      git add -A
      git commit -m "Reporte del <fecha>"
      git push origin main

   Esto es lo que actualiza la pagina que ve Francisco ($PagesUrl).
   Sin push, el reporte queda solo en esta compu y el no ve nada nuevo.
   Si el push falla, anotalo en el log del paso 8 con las palabras PUSH FALLIDO.

8. IMPRESCINDIBLE, HACELO SIEMPRE AL FINAL. Cuando termines todo lo anterior, AGREGA una
   linea al final del archivo de log:

      $logFile

   Usa la herramienta Edit o Write para agregarla SIN borrar lo que ya tiene. Formato exacto:

      [HH:mm:ss] CLAUDE OK | CDR <precio> | resultado <pesos> | push <ok|FALLIDO>

   Si algo fallo, escribi en su lugar:

      [HH:mm:ss] CLAUDE ERROR | <que fallo>

   Esta linea es la UNICA prueba confiable de que la corrida termino, porque el script que
   te lanza a veces muere antes de poder escribirla. No la omitas por ningun motivo.

Al terminar, escribi ademas un resumen de una sola linea con: precio del CDR, resultado
acumulado en pesos, y si el dashboard se republico correctamente.
"@

$promptFile = Join-Path $Logs "$hoy.prompt.txt"
Set-Content -Path $promptFile -Value $prompt -Encoding utf8

$salida  = Join-Path $Logs "$hoy.salida.txt"
$errores = Join-Path $Logs "$hoy.errores.txt"

# --- Ubicar node.exe y el cli.js de Claude ---------------------------
# NO usar claude.cmd: ese wrapper batch hace 'title %COMSPEC%' y otros
# trucos que necesitan una consola real. Como la tarea programada corre
# sin ventana, el batch muere con STATUS_CONTROL_C_EXIT (0xC000013A) y
# Claude nunca llega a arrancar. Llamando a node directamente sobre
# cli.js el problema desaparece.
$NodeExe = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $NodeExe) { $NodeExe = 'C:\Program Files\nodejs\node.exe' }
$ClaudeCli = Join-Path $env:APPDATA 'npm\node_modules\@anthropic-ai\claude-code\cli.js'

if (-not (Test-Path $NodeExe)) {
    Log "ERROR: no se encontro node.exe en '$NodeExe'."
    exit 1
}
if (-not (Test-Path $ClaudeCli)) {
    Log "ERROR: no se encontro el cli.js de Claude en '$ClaudeCli'."
    exit 1
}

# NO usar Start-Process -NoNewWindow con flujos redirigidos: la tarea
# programada corre en una sesion SIN consola, y esa combinacion mata al
# propio PowerShell con STATUS_CONTROL_C_EXIT (0xC000013A) antes de que
# Claude llegue a arrancar. System.Diagnostics.Process no depende de la
# consola y funciona igual con ventana o sin ella.
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName               = $NodeExe
$psi.Arguments              = '"{0}" -p --allowedTools WebFetch,WebSearch,Read,Write,Edit,Bash --permission-mode acceptEdits' -f $ClaudeCli
$psi.WorkingDirectory       = $Proyecto
$psi.UseShellExecute        = $false
$psi.CreateNoWindow         = $true
$psi.RedirectStandardInput  = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8

Log "Lanzando Claude Code (timeout: $TimeoutMin min)..."

$textoSalida = ''
$textoError  = ''

try {
    $proc = [System.Diagnostics.Process]::Start($psi)

    # Leer los dos flujos de forma asincronica ANTES de esperar, si no
    # el proceso puede quedarse trabado llenando un buffer.
    $tOut = $proc.StandardOutput.ReadToEndAsync()
    $tErr = $proc.StandardError.ReadToEndAsync()

    # El prompt va por stdin, no por linea de comandos.
    $proc.StandardInput.Write($prompt)
    $proc.StandardInput.Close()

    if (-not $proc.WaitForExit($TimeoutMin * 60 * 1000)) {
        $proc.Kill()
        Log "ERROR: se paso de $TimeoutMin minutos. Proceso terminado a la fuerza."
        exit 1
    }

    $textoSalida = $tOut.Result
    $textoError  = $tErr.Result
    Log "Claude termino (codigo: $($proc.ExitCode))."
}
catch {
    Log "ERROR inesperado al lanzar Claude: $($_.Exception.Message)"
    exit 1
}

# --- Que dijo -------------------------------------------------------
if ($textoSalida) {
    Set-Content -Path $salida -Value $textoSalida -Encoding utf8
    Log "Resumen: $($textoSalida.Trim())"
}
if ($textoError) {
    Set-Content -Path $errores -Value $textoError -Encoding utf8
    Log "stderr: $($textoError.Trim())"
}

# --- Verificacion real: agrego la fila de hoy? ------------------------
if (Select-String -Path $Historial -Pattern "^$hoy," -Quiet) {
    Log "OK: historial.csv tiene la fila de $hoy."
    Log "=== Fin de la corrida ==="
    exit 0
}
else {
    Log "ATENCION: no se agrego la fila de $hoy al historial. Puede ser feriado, o algo fallo. Revisar $salida"
    Log "=== Fin de la corrida (sin fila nueva) ==="
    exit 0
}
