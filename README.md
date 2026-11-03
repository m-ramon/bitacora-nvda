# Bitácora NVDA — seguimiento diario

Proyecto de Mariano y Francisco. Seguimiento de 4 CDR de NVIDIA comprados el 10/08/2026 a
14.410 pesos, en Nación Bursátil.

**Tablero:** https://m-ramon.github.io/bitacora-nvda/

> ⚠️ **Este repositorio es público.** Se hizo público a propósito, para que GitHub Pages pueda
> servir el tablero sin costo. No poner acá nada que no pueda ser leído por cualquiera: ni
> números de cuenta, ni claves, ni apellidos, ni datos de contacto.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | El tablero. Es lo que GitHub Pages publica. Se regenera entero cada día. |
| `historial.csv` | Una fila por día. Es la base de datos. |
| `posicion.json` | Ficha de la posición: compra, ratio, costos, meta, objetivos. Se edita a mano. |
| `reporte-diario.ps1` | El script que corre solo todos los días. |
| `gen_tabla.py` | Ayudante. Desde `historial.csv` escribe el `<tbody>` del historial en `tbody.html` e imprime toda la geometría del día (barras, marcadores, termómetro) ya calculada con las fórmulas de más abajo. Sirve para no hacer esas cuentas a mano ni olvidarse una fila. |
| `logs/` | Un log por día de cada corrida. No se versiona. |

## Datos de referencia

- **Ratio del CDR: 24 CDR = 1 acción de NVIDIA** (0,04166667 acciones por CDR).
- Posición: 4 CDR = 0,166667 acciones.
- Monto bruto 57.640 ARS + 378 de costos = **costo total 58.017,54 ARS**.
- BYMA: el horario de 11:00 a 17:00 que decía acá **está mal o incompleto para los CEDEAR**.
  El 02/11/2026 se vio el CDR operando a las **10:54** y todavía a las **17:51**, las dos veces
  con el volumen creciendo. **Hay que averiguar el horario real antes de fijar la hora del
  disparador.** (Hora argentina, UTC−3 todo el año.)
- ⚠️ **NASDAQ cierra a las 18:00 hora argentina entre el 01/11/2026 y el 08/03/2027**, porque
  Estados Unidos salió del horario de verano y quedó en UTC−5. El resto del año cierra 17:00.
  **El reporte se hace después del cierre de los DOS mercados**, así que en este período no
  puede salir antes de las 18:00. Ver `horarios._ojo_dst` en `posicion.json`.

### Costos (confirmados por el boleto)

Comisión Nación Bursátil **0,50 %** + IVA 21 % + derechos de mercado BYMA 0,05 %:

```
costo por punta = 0.5% * 1.21 + 0.05% = 0.655%
```

Se paga **dos veces**: al comprar y al vender.

**Punto de equilibrio: 14.600 ARS** (+1,32 % sobre el precio de compra). Por debajo de ese
precio, aunque la app del broker muestre ganancia, vender da pérdida.

### Objetivos de Francisco (fijados el 10/08/2026)

Se miden sobre la **ganancia real, neta de comisiones de compra y venta**. En los dos casos
vende los 4 CDR.

| Disparador | Precio del CDR | Variación de precio | Resultado |
|---|---|---|---|
| Gana 20 % | **17.520** | +21,58 % | +11.604 ARS |
| Empata | 14.600 | +1,32 % | 0 |
| Pierde 15 % | **12.410** | −13,88 % | −8.703 ARS |

Los porcentajes de precio y de resultado NO coinciden: para ganar 20 % real el precio tiene
que subir 21,58 %; para perder 15 % real alcanza con que baje 13,88 %.

**Después de vender, vuelve a comprar.** Con todo el dinero reingresa y los disparadores se
recalculan sobre el precio nuevo. La venta es un reinicio, no una salida del plan. Cada vuelta
cuesta 0,655 % al salir + 0,655 % al volver a entrar (~910 ARS sobre 69.600).

### La meta

**400.000 pesos, medidos en pesos del 10/08/2026** — se ajusta por inflación, no es nominal.
Aporte de **30.000 por mes, en la primera semana de cada mes**.

| | |
|---|---|
| Avance | 14,5 % (58.018 de 400.000) |
| Ventana de aporte en curso | **1 al 7 de noviembre de 2026** — todavía sin registrar |
| Aportes vencidos sin hacer | septiembre y octubre de 2026 (60.000) |
| Plazo si ajusta el aporte por inflación | 11,4 meses → **12 aportes** |
| Plazo si deja el aporte fijo en 30.000 | 13 meses → **13 aportes** |
| Meta nominal estimada | ≈ 510.886 ARS |

Inflación: **1,9 % mensual**, dato real del IPC del INDEC de septiembre 2026 (33,4 %
interanual, 23,6 % acumulado en 2026). Historia: julio 2,1 % · agosto 1,7 % · septiembre 1,9 %.

**No ajustar el aporte cuesta un aporte extra** (13 en vez de 12). Con el 2,1 % de julio
costaba dos; bajó a uno cuando la inflación cedió a 1,7 % y se mantuvo con el 1,9 %.

⚠️ **Los plazos suponen un aporte por mes sin faltar, y faltaron dos**, así que el calendario
real ya corre dos meses atrasado respecto de este estimado.

**Regla mensual:** cuando el INDEC publica el IPC (alrededor del día 13), actualizar el bloque
`meta.inflacion` de `posicion.json` con el dato real y recalcular la meta nominal.

⚠️ **Ojo con el calendario de noviembre:** el IPC de octubre sale alrededor del **13/11**, o sea
**después** de que cierre la ventana de aportes del 01 al 07/11. La decisión de cuánto aportar
este mes hay que tomarla con el dato de septiembre.

## Cómo se publica el tablero

`index.html` vive en la raíz del repo y **GitHub Pages lo sirve automáticamente en cada push**.
No hace falta ninguna herramienta de publicación: `git push` es la publicación.

Esto reemplaza el esquema anterior con Artifacts, que no funcionaba automatizado:
**la herramienta Artifact no existe en modo headless** (`claude -p`), así que ninguna tarea
programada podía refrescar aquel link. Con Pages el problema desaparece de raíz.

**`index.html` es un documento HTML completo** — doctype, `<head>` con `charset` y `viewport`.
Al regenerarlo hay que conservar ese esqueleto: sin `viewport` el tablero se ve diminuto en el
celular, y sin `charset` se rompen los acentos. Antes vivía en formato "fragmento" porque la
plataforma de Artifacts le agregaba el esqueleto sola; Pages no hace eso.

## Automatización

La tarea **«Bitacora NVDA - reporte diario»** del Programador de tareas de Windows ejecuta
`reporte-diario.ps1`. Corre como usuario común, sin privilegios elevados.

**Dos disparadores**, porque uno solo no alcanzaba:

| Disparador | Cuándo | Para qué |
|---|---|---|
| Diario | Días hábiles 17:35 | La rueda del día — ⚠️ **hay que moverlo a 18:15**, ver abajo |
| Al iniciar sesión | 5 min después de prender | Recuperar lo que se haya perdido |

Más `WakeToRun` (despierta la máquina si está suspendida) y `StartWhenAvailable` (si se pasó
la hora, corre apenas puede).

> ⚠️ **ACTUALIZACIÓN DEL 03/11/2026 — ESTO YA COSTÓ UN DÍA.** La rueda del 02/11 no la pudo
> cerrar ninguno de los dos disparadores y la terminó cargando la corrida de inicio de sesión
> del día siguiente, a las 09:50. Es la primera vez que se pierde una rueda **en el día** con
> la computadora prendida y las dos corridas ejecutándose bien. Lo salvó la recuperación
> automática, que publica un día tarde. **Y el horario nuevo todavía NO se puede fijar en
> 18:15**: el 02/11 se vio al CDR operando a las 17:51 con el volumen creciendo, así que
> primero hay que averiguar a qué hora cierra de verdad la rueda de CEDEAR. Si cierra cerca de
> las 18:00, el disparador va a las **18:30 o 18:45**. Dato que apoya esperar: la ficha de Rava
> del 02/11 recién quedó coherente en el sello de las **18:46**.
>
> ⚠️ **PENDIENTE ABIERTO DESDE EL 02/11/2026: el disparador de las 17:35 ya no sirve.**
> Estados Unidos terminó el horario de verano el 01/11 y NASDAQ pasó a cerrar 18:00 ART, así
> que la corrida de las 17:35 llega 25 minutos **antes** del cierre de NVIDIA y no puede
> armar una fila completa — le falta la mitad del dato. Y la de inicio de sesión de la mañana
> cae antes de la **apertura** de Nueva York, así que tampoco. **Hoy ninguno de los dos
> disparadores puede cerrar una rueda.** Hay que mover el diario a **18:15**, que de paso
> resuelve el pendiente viejo de esperar la consolidación de la ficha de Rava (que el 22/10 y
> el 30/10 selló 18:04). Se arregla así:
>
> ```powershell
> $t = New-ScheduledTaskTrigger -Daily -At 18:15
> Set-ScheduledTask -TaskName 'Bitacora NVDA - reporte diario' -Trigger $t
> ```
>
> Ojo que esto **se da vuelta solo el 08/03/2027**, cuando EE.UU. retome el horario de verano.

### Ninguna rueda se pierde

El 14/08/2026 se perdió un día entero: la compu estaba apagada a las 17:35 y nadie lo notó
hasta el lunes. Para que no vuelva a pasar, la corrida **recupera sola los días faltantes**.

Al arrancar evalúa tres motivos para trabajar, y le basta con **uno**:

1. Hoy hay rueda y todavía no se registró.
2. Faltan ruedas viejas en el historial → las recupera una por una, de la más vieja a la más
   nueva, con el histórico de Rava y el de StockAnalysis.
3. El tablero quedó atrasado respecto del CSV → lo regenera y publica.

Si no se cumple ninguno, sale en un segundo sin gastar nada. Por eso el disparador de inicio
de sesión es barato: casi siempre no hay nada que hacer.

**Los datos recuperados nunca se estiman.** Si un día no se consiguen los precios reales, esa
fila queda sin cargar y se dice en la nota. Y toda fila recuperada lleva anotado en su nota
que se cargó después y de dónde salieron los precios.

```powershell
Get-ScheduledTaskInfo -TaskName 'Bitacora NVDA - reporte diario'   # cuándo corrió / cuándo corre
Start-ScheduledTask    -TaskName 'Bitacora NVDA - reporte diario'  # correrla ahora
Disable-ScheduledTask  -TaskName 'Bitacora NVDA - reporte diario'  # apagarla
```

### Trampas técnicas ya resueltas, no volver a pisarlas

1. **El prompt va por entrada estándar**, no como argumento de línea de comandos. Si se pasa
   como argumento, Windows lo parte en palabras sueltas y Claude recibe sólo la primera. Por
   el mismo motivo la lista de herramientas va separada por comas, no por espacios.

2. **El código de salida miente.** El script de PowerShell muere al final con
   `STATUS_CONTROL_C_EXIT` (`0xC000013A`): Claude Code es una app de terminal y al salir
   dispara un evento de consola que mata al proceso padre. **El reporte se genera bien igual.**
   Se intentaron cuatro arreglos sin éxito (llamar a node directo, `System.Diagnostics.Process`,
   `SetConsoleCtrlHandler`, ventana visible). Por eso **NO usar el `LastTaskResult` para saber
   si anduvo.**

3. **La herramienta Artifact no existe en headless.** Ver la sección de arriba.

### Cómo saber si corrió

1. **La línea que escribe Claude** al final del log: `CLAUDE OK | CDR ... | push ok`.
2. **La última fila de `historial.csv`** — si tiene la fecha de hoy, corrió.
3. **La recuperación automática** — si falta una rueda, la corrida siguiente la detecta, la
   carga y lo deja anotado en el log. Ya no hace falta vigilar: un día perdido se recupera
   solo en cuanto la compu vuelva a estar prendida.

```powershell
Get-Content 'C:\Users\maria\Codigo\10_Finanzas\historial.csv' | Select-Object -Last 1
```

## Procedimiento diario

0. **Antes que nada: ¿falta alguna rueda?** Comparar la última fecha de `historial.csv` con
   hoy. Si hay días hábiles sin registrar, recuperarlos primero, del más viejo al más nuevo,
   con el histórico de Rava y https://stockanalysis.com/stocks/nvda/history/. Nunca estimar:
   si no hay dato real, la fila no se carga y se dice en la nota.

1. **Buscar los tres precios.** Cada uno se lee de dos fuentes y **se cruza antes de publicar.**
   - CDR NVDA en pesos — primaria https://www.rava.com/perfil/NVDA
     (último, variación %, cierre anterior, mínimo, máximo, volumen nominal),
     secundaria https://iol.invertironline.com/titulo/cotizacion/BCBA/NVDA
   - NVIDIA en dólares — primaria https://stockanalysis.com/stocks/nvda/,
     secundaria https://finance.yahoo.com/quote/NVDA/
     (**Google Finance está descartado**: devuelve «isn't supported on this device».)

   Tres controles, en este orden, antes de usar cualquier precio:

   1. **Coherencia interna de la ficha** (una sola división, no necesita la segunda fuente):
      que `último / cierre_anterior − 1` reproduzca la variación % que la ficha publica. Si no
      cierra, la ficha está mezclada y **no se usa**, aunque diga «sesión cerrada». El 02/11
      Rava mostró último 14.210, cierre anterior 14.180 y −1,48 % a la vez, con la ficha
      declarándose consolidada: los tres números no pueden convivir.
   2. **La secundaria rodó de sesión**: su rango y su volumen no pueden ser iguales a los de la
      última fila de `historial.csv`. Si lo son, todavía está en la rueda anterior y no sirve
      para cruzar.
   3. **El cruce.** Al cierre se exige coincidencia **al peso** en último, mínimo, máximo y
      variación %; si difieren, no se publica. Intradiario alcanza con que coincida el rango y
      que cada último caiga dentro del rango del otro.

   Detalles de cada fuente (defectos conocidos, uno por uno) en los bloques `_ojo_*` de
   `posicion.json`. Los dos que más pegan: **de InvertirOnline no se lee nunca la variación
   absoluta** (viene mal seis ruedas al hilo, el % sí está bien), y **el rango de NVIDIA se
   toma de Yahoo**, porque el mínimo de StockAnalysis viene atrasado.

2. **Calcular**
   ```
   ccl_implicito   = cdr_ars * 24 / nvda_usd
   valor_pos_ars   = 4 * cdr_ars
   pnl_ars         = valor_pos_ars - 57640          # ganancia EN PAPEL
   pnl_pct         = pnl_ars / 57640 * 100
   valor_pos_usd   = 0.166667 * nvda_usd

   # El resultado que importa: lo que le quedaria si vendiera hoy
   neto_venta_ars  = valor_pos_ars * (1 - 0.00655)
   resultado_ars   = neto_venta_ars - 58017.54
   resultado_pct   = resultado_ars / 58017.54 * 100
   ```

3. **Verificar la descomposición** (control de que los datos son coherentes):
   ```
   (1 + var_nvda) * (1 + var_ccl) = (1 + var_cdr)
   ```
   Si no cierra con un margen chico, algún precio está mal tomado. Revisar antes de seguir.
   Si una fuente muestra una variación incoherente con sus propios precios, recalcularla desde
   los precios y dejarlo anotado en la nota.

4. **Agregar una fila a `historial.csv`.** El campo `estado` es `cierre` para las corridas de
   después de las 17:00, `intradiario` si se tomó con el mercado abierto. Si ya existe una
   fila de hoy en estado `intradiario`, **reemplazarla** — nunca duplicar el día. Las filas de
   días anteriores no se tocan.

5. **Regenerar `index.html`**. La tabla de Historial tiene que listar **TODAS** las filas de
   `historial.csv`, sin excepción — es fácil regenerar el resto del tablero y olvidarse de
   agregar la fila nueva a esa tabla (ya pasó una vez con un día recuperado). El contador de
   «N registros» tiene que coincidir con la cantidad de filas. con los datos nuevos, conservando el esqueleto HTML completo y la
   estructura: masthead → resultado → los dos motores → rango del día → contexto de NVIDIA →
   costos → objetivos → meta → nota del día → pendientes → historial → pie. Actualizar el
   contador de «Día N», el de registros, y la posición del marcador «Hoy» en el termómetro.

6. **Commit y push.** `git add -A && git commit -m "..." && git push origin main`.
   Eso publica el tablero. Sin push, Francisco no ve nada nuevo.

## Geometría del tablero (fórmulas exactas)

Varios elementos se posicionan con porcentajes calculados. **Hay que recalcularlos cada día.**
Estas son las fórmulas; si se improvisan, el tablero se rompe visualmente.

### Barras de los dos motores — `.fill`

Escala fija de **±3 %**, y cada barra **sale del centro**, así que dispone de la **mitad** de
la pista, no de toda:

```
width % = min( |variacion| / 3 * 50 , 50 )
clase   = "fill left"  si la variacion es negativa
          "fill right" si es positiva
```

Ejemplo: −2,86 % → `2.86 / 3 * 50` = **47,7 %**

> **Error típico, ya cometido una vez:** multiplicar por 100 en vez de por 50. Da 95,3 % y la
> barra se sale de la pista por la izquierda. El máximo posible es 50 %.

Si alguna variación supera el 3 %, subir la escala (por ejemplo a ±5 %) **y actualizar los tres
rótulos de `.motor-scale`**, que hoy dicen −3 % / 0 / +3 %.

### Marcadores del rango del día — `.mark` de la primera `.range-track`

```
left % = (precio - minimo_del_dia) / (maximo_del_dia - minimo_del_dia) * 100
```

Se marcan tres: el cierre de hoy (`data-kind="now"`), el precio de compra (`buy`, siempre
14.410) y el cierre anterior (`prev`). **`now` va con `data-pos="below"` y los otros dos con
`data-pos="above"`**, para que las etiquetas no se pisen cuando los precios quedan cerca.

### Marcador de 52 semanas — segunda `.range-track`

```
left % = (nvda_usd - 164.07) / (236.54 - 164.07) * 100
```

Si NVIDIA hace un máximo o mínimo nuevo, actualizar los extremos en `posicion.json` y en los
rótulos de `.range-ends`.

### Termómetro de objetivos — `.today` y `.breakeven`

Escala de **12.410 a 17.520** (los dos disparadores), rango 5.110:

```
left % = (precio - 12410) / 5110 * 100
```

- `.breakeven` es fijo en **42,86 %** (los 14.600).
- Las zonas de color acompañan: `.zone.loss` 42,86 % y `.zone.gain` 57,14 %.
- Si el precio se sale del rango, hay que ampliar la escala: quedaría fuera de la pista.

### Barra de la meta — `.meta-fill`

```
width % = capital_aportado / 400000 * 100
```

**Ojo: es el capital APORTADO, no el valor de mercado.** No se mueve con el precio del CDR —
sólo cambia cuando Francisco hace un aporte nuevo. Hoy: 58.018 / 400.000 = 14,5 %.

## Reglas de contenido

- **El número principal es el resultado REAL** (neto de la comisión de venta), no la ganancia
  en papel. Mostrar la ganancia en papel como dato secundario, aclarando que es lo que muestra
  la app del broker.
- **Separar siempre los dos motores.** Cuánto del movimiento vino de NVIDIA y cuánto del
  dólar. Es el punto del proyecto.
- **Avisar si se cruza un disparador** (17.520 o 12.410) o si se acerca a menos del 3 %.
- **Los días 1 al 7 de cada mes, recordar el aporte de 30.000** en un bloque destacado arriba
  del tablero, y avisar si todavía no se registró. Recordar también que conviene subirlo con la
  inflación, o el plan se estira de 12 a 13 meses.
- **No recomendar comprar ni vender.** El tablero informa y compara contra los objetivos que
  Francisco ya fijó. La decisión es suya.
- **Si un dato no se consigue, decirlo.** Dejar el campo vacío y aclararlo en la nota. Nunca
  estimar un precio ni completar con el del día anterior como si fuera de hoy.
- **La nota del día en criollo**, dos o tres párrafos, explicando qué pasó y por qué.
- Días sin rueda (feriados, fin de semana): no se agrega fila.

## Pendientes

- [ ] **Mover el disparador diario de las 17:35.** Es lo más urgente: hasta que no se haga,
      **ninguna corrida automática puede cerrar una rueda**. Ya no es preventivo — **el 02/11
      costó un día de atraso en la publicación** (ver abajo). ⚠️ **La hora nueva todavía no se
      puede fijar**: depende del pendiente que sigue. Si la rueda del CDR cierra cerca de las
      18:00, el disparador va a las 18:30 o 18:45, no a las 18:15.
- [ ] **Averiguar a qué hora cierra de verdad BYMA para los CEDEAR.** El 02/11 se vio el CDR
      operando a las **10:54** y todavía a las **17:51**, las dos veces con el volumen
      creciendo. El `11:00 a 17:00` que figura más arriba está mal o incompleto. Puede ser
      sesión extendida de CEDEAR, subasta de cierre, o que BYMA haya corrido la rueda para
      seguir a Nueva York. **Bloquea el pendiente anterior.**
- [ ] **Conseguir una tercera fuente del CDR en pesos.** El 03/11 se extrañó: Rava e
      InvertirOnline discreparon 10 pesos en el cierre del 02/11 y no hubo con qué desempatar.
      **Cohen y Facimex fallaron las dos con error de certificado TLS**, y el histórico de Rava
      devolvió 404 en dos variantes de URL. Candidato a probar: BYMA Data abierto
      (`open.bymadata.com.ar`).
- [ ] **Pasarle a InvertirOnline el control de coherencia interna.** El defecto de esa fuente
      empeoró: van **siete ruedas** publicando mal la variación absoluta, y el 02/11 **por
      primera vez arrastró también el último precio** (imprimió 13.970 cuando su propio
      porcentaje da 13.960). La regla vieja —leer de ahí el precio, el rango, el volumen y el
      porcentaje— ya no alcanza.
- [ ] **Decidir cómo se calcula el CCL implícito ahora que los dos cierres no son simultáneos**
      (NASDAQ cierra una hora después que BYMA hasta el 08/03/2027). Recomendación: seguir
      pareando los dos cierres oficiales y anotar el desfasaje como ruido conocido. Está
      planteado en `horarios._ojo_dst` de `posicion.json`.
- [ ] **Que `gen_tabla.py` avise solo.** Cuatro alarmas que hoy se chequean a mano: coherencia
      interna de cada fuente (la más valiosa — detectó la ficha rota del 02/11 con una
      división), récord o salto anómalo del CCL, variación que se sale de la escala de las
      barras, y precio a menos del 3 % del punto de equilibrio.
- [ ] Cargar el IPC de octubre cuando salga (~13/11) y recalcular la meta nominal.
- [ ] Con ~2 semanas de datos, agregar el gráfico de evolución al tablero.
- [x] **Rueda del 02/11/2026 recuperada** (03/11 09:50). Cerró en **13.960** (−1,55 %). Era el
      caso difícil y se resolvió sin el histórico de Rava, que devolvió 404: la ficha en vivo
      ya consolidada (sello 02/11 18:46) pasó el control de coherencia interna, y se cruzó con
      InvertirOnline. **El cruce no fue al peso** —10 pesos de diferencia en el precio— y se
      publicó igual, con el criterio escrito en `_ojo_cdr_ars`: cuando las dos fuentes
      discrepan en el precio, se publica la que cierra consigo misma y se deja anotado.
- [x] **Control de coherencia interna de la ficha** (02/11): verificar que
      `último / cierre_anterior − 1` reproduzca la variación % que la propia ficha publica,
      antes de cruzar. Detecta un modo de falla que el cruce solo no explica, con una división
      y una sola fuente.
- [x] Fuentes del `Procedimiento diario` actualizadas (02/11/2026): Google Finance afuera,
      StockAnalysis + Yahoo para NVIDIA, Rava + InvertirOnline para el CDR, y los tres
      controles del cruce escritos en el paso 1.
- [x] Comisión real confirmada (0,5 %).
- [x] Objetivos de salida definidos, con regla de reingreso.
- [x] Meta de acumulación definida (400.000 en pesos de hoy, 30.000/mes).
- [x] Automatizar con el Programador de tareas de Windows.
- [x] Publicación automática con GitHub Pages.

## Fechas a tener en cuenta

- **13/08/2026** — INDEC publica el IPC de julio.
- **26/08/2026** — NVIDIA presenta resultados trimestrales.
- **~ago/sep 2027** — fecha estimada de llegada a la meta.
