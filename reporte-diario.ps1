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
$TimeoutMin  = 25   # mas alto que antes: recuperar varios dias lleva su tiempo

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

# --- Que hay para hacer? ---------------------------------------------
# Tres motivos posibles para correr, y basta con UNO:
#   a) hoy hay rueda y todavia no se registro
#   b) faltan ruedas viejas (la compu estuvo apagada) -> hay que recuperarlas
#   c) el tablero quedo atrasado respecto del CSV
# Antes se salia temprano por fin de semana o por "ya corrio hoy", y eso
# hacia que un dia perdido no se recuperara NUNCA.

$Index = Join-Path $Proyecto 'index.html'
$esFinde = ((Get-Date).DayOfWeek -eq 'Saturday') -or ((Get-Date).DayOfWeek -eq 'Sunday')

# (b) faltan ruedas?
$hayFaltantes = $false
if (Test-Path $Historial) {
    $fechas = Get-Content $Historial -Encoding utf8 |
              Select-Object -Skip 1 |
              Where-Object { $_ -match '^\d{4}-\d{2}-\d{2},' } |
              ForEach-Object { [datetime]($_ -split ',')[0] }

    if ($fechas) {
        $ultima = ($fechas | Sort-Object)[-1]
        $previa = (Get-Date).Date.AddDays(-1)
        while ($previa.DayOfWeek -eq 'Saturday' -or $previa.DayOfWeek -eq 'Sunday') {
            $previa = $previa.AddDays(-1)
        }
        if ($ultima.Date -lt $previa) {
            $hayFaltantes = $true
            $faltan = [int]($previa - $ultima.Date).TotalDays
            Log "FALTAN RUEDAS: el ultimo registro es del $($ultima.ToString('yyyy-MM-dd')) y la rueda anterior fue el $($previa.ToString('yyyy-MM-dd')) (unos $faltan dias). Se van a recuperar en esta corrida."
        }
    }
}

# (c) tablero atrasado respecto del CSV?
$tableroViejo = $false
if ((Test-Path $Index) -and (Test-Path $Historial)) {
    $tableroViejo = (Get-Item $Historial).LastWriteTimeUtc -gt (Get-Item $Index).LastWriteTimeUtc
    if ($tableroViejo) { Log "El tablero esta atrasado respecto del historial. Se regenera." }
}

# (a) ya se registro el cierre de hoy?
$filaHoy = $null
if (Test-Path $Historial) {
    $filaHoy = Select-String -Path $Historial -Pattern "^$hoy," | Select-Object -First 1
}
$hoyListo = ($filaHoy -and $filaHoy.Line -match "^$hoy,[^,]*,cierre,")
if ($filaHoy -and -not $hoyListo) {
    Log "Hay una fila intradiaria de $hoy. Se va a reemplazar por los datos del cierre."
}

# Nada que hacer?
if ($esFinde -and -not $hayFaltantes -and -not $tableroViejo) {
    Log "Fin de semana y no falta nada. BYMA no opera. Sin trabajo."
    exit 0
}
if ($hoyListo -and -not $hayFaltantes -and -not $tableroViejo) {
    Log "El historial ya tiene la fila de cierre de $hoy y no falta nada mas. Sin trabajo."
    exit 0
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
4. RECUPERAR DIAS FALTANTES. Antes de nada, compara la ultima fecha de historial.csv contra
   hoy. Si faltan ruedas en el medio (la compu pudo haber estado apagada), RECUPERALAS una
   por una ANTES de hacer la de hoy, de la mas vieja a la mas nueva:
     - CDR: la ficha de Rava muestra la ultima rueda operada; para dias mas viejos usar el
       historico de Rava.
     - NVIDIA: https://stockanalysis.com/stocks/nvda/history/ tiene el cierre de cada dia.
     - Si un dia no fue rueda (feriado o fin de semana), NO inventes fila: saltealo.
     - Si de plano no conseguis los datos de un dia, dejalo sin fila y decilo en la nota.
       Nunca estimes un precio ni copies el del dia anterior.
     - En la nota de una fila recuperada, aclara SIEMPRE que se recupero despues y de donde
       salieron los precios.
   Ninguna rueda se puede perder: si un dia no entro a tiempo, entra despues.

5. Si hoy BYMA no opero (feriado o fin de semana), no agregues fila de hoy. PERO igual
   revisa el paso 4 y el paso 6: puede haber dias viejos para recuperar o el tablero puede
   estar desactualizado.
6. Si algun precio no se consigue, no lo estimes ni lo copies del dia anterior. Deja el
   campo vacio y decilo en la nota del dia.
7. Si historial.csv YA tiene una fila de hoy con estado 'intradiario', REEMPLAZALA por los
   datos del cierre (estado 'cierre'). No agregues una fila duplicada para el mismo dia.

7b. EL TABLERO NUNCA QUEDA ATRASADO. Aunque hoy no haya rueda, si index.html no refleja
   la ULTIMA fila de historial.csv (por ejemplo porque se recupero un dia viejo), regeneralo
   igual y publicalo. El tablero siempre muestra la ultima rueda registrada.

8. PUBLICAR. Cuando el reporte este listo, hace commit y push con Bash:

      git add -A
      git commit -m "Reporte del <fecha>"
      git push origin main

   Esto es lo que actualiza la pagina que ve Francisco ($PagesUrl).
   Sin push, el reporte queda solo en esta compu y el no ve nada nuevo.
   Si el push falla, anotalo en el log del paso 9 con las palabras PUSH FALLIDO.

9. IMPRESCINDIBLE, HACELO SIEMPRE AL FINAL. Cuando termines todo lo anterior, AGREGA una
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
