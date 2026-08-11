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
| `logs/` | Un log por día de cada corrida. No se versiona. |

## Datos de referencia

- **Ratio del CDR: 24 CDR = 1 acción de NVIDIA** (0,04166667 acciones por CDR).
- Posición: 4 CDR = 0,166667 acciones.
- Monto bruto 57.640 ARS + 378 de costos = **costo total 58.017,54 ARS**.
- BYMA opera de 11:00 a 17:00. El reporte se hace después del cierre.

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
| Próximo aporte | 1 al 7 de septiembre de 2026 |
| Plazo con aporte ajustado por inflación | 12 meses |
| Plazo con aporte fijo en 30.000 | 13 meses |
| Meta nominal estimada | ≈ 517.440 ARS |

Supuesto de inflación: **2,0 % mensual** (REM del BCRA, junio 2026). Último dato real del
INDEC: 1,9 % mensual, 33,5 % interanual (junio 2026).

**Regla mensual:** cuando el INDEC publica el IPC (alrededor del día 13), actualizar el bloque
`meta.inflacion` de `posicion.json` con el dato real y recalcular la meta nominal.

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

Una tarea del Programador de tareas de Windows llamada **«Bitacora NVDA - reporte diario»**
ejecuta `reporte-diario.ps1` los días hábiles a las **17:35**. Corre como usuario común, sin
privilegios elevados, y con recuperación si la compu estuvo apagada.

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
3. **El aviso automático** — si falta la rueda anterior, la corrida siguiente lo escribe en el
   log al arrancar. Un día perdido no pasa desapercibido más de 24 horas.

```powershell
Get-Content 'C:\Users\Usuario\Desktop\10_Finanzas\historial.csv' | Select-Object -Last 1
```

## Procedimiento diario

1. **Buscar los tres precios**
   - CDR NVDA en pesos: https://www.rava.com/perfil/NVDA
     (último, variación %, cierre anterior, mínimo, máximo, volumen nominal)
   - NVIDIA en dólares: https://www.google.com/finance/quote/NVDA:NASDAQ
     (último, cierre anterior)
   - Si hace falta contexto: https://stockanalysis.com/stocks/nvda/

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

5. **Regenerar `index.html`** con los datos nuevos, conservando el esqueleto HTML completo y la
   estructura: masthead → resultado → los dos motores → rango del día → contexto de NVIDIA →
   costos → objetivos → meta → nota del día → pendientes → historial → pie. Actualizar el
   contador de «Día N», el de registros, y la posición del marcador «Hoy» en el termómetro.

6. **Commit y push.** `git add -A && git commit -m "..." && git push origin main`.
   Eso publica el tablero. Sin push, Francisco no ve nada nuevo.

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

- [ ] Cargar el IPC de julio cuando salga (13/08) y recalcular la meta nominal.
- [ ] Con ~2 semanas de datos, agregar el gráfico de evolución al tablero.
- [x] Comisión real confirmada (0,5 %).
- [x] Objetivos de salida definidos, con regla de reingreso.
- [x] Meta de acumulación definida (400.000 en pesos de hoy, 30.000/mes).
- [x] Automatizar con el Programador de tareas de Windows.
- [x] Publicación automática con GitHub Pages.

## Fechas a tener en cuenta

- **13/08/2026** — INDEC publica el IPC de julio.
- **26/08/2026** — NVIDIA presenta resultados trimestrales.
- **~ago/sep 2027** — fecha estimada de llegada a la meta.
