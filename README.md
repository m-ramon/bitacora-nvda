# Bitácora NVDA — seguimiento diario

Proyecto de Mariano y Francisco. Seguimiento de 4 CDR de NVIDIA comprados el 10/08/2026 a
14.410 pesos, en Nación Bursátil.

**Dashboard:** https://claude.ai/code/artifact/05409e21-4d6e-4733-9ddd-e8d7ee255440

## Archivos

| Archivo | Qué es |
|---|---|
| `posicion.json` | Ficha de la posición: compra, ratio, costos, objetivos, fuentes. Se edita a mano. |
| `historial.csv` | Una fila por día. Es la base de datos. |
| `dashboard.html` | El tablero. Se regenera entero cada día a partir del CSV. |
| `reporte-diario.ps1` | El script que corre solo todos los días. |
| `logs/` | Un log por día de cada corrida automática. |

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
vende los 4 CDR y cierra la posición.

| Disparador | Precio del CDR | Variación de precio | Resultado |
|---|---|---|---|
| Gana 20 % | **17.520** | +21,58 % | +11.604 ARS |
| Empata | 14.600 | +1,32 % | 0 |
| Pierde 15 % | **12.410** | −13,88 % | −8.703 ARS |

Nota: los porcentajes de precio y de resultado NO coinciden. Para ganar 20 % real el precio
tiene que subir 21,58 %; para perder 15 % real alcanza con que baje 13,88 %. Las comisiones
corren los dos números en contra.

**Después de vender, vuelve a comprar.** Con todo el dinero reingresa y los disparadores se
recalculan sobre el precio nuevo. La venta es un reinicio, no una salida del plan. Cada vuelta
cuesta 0,655 % al salir + 0,655 % al volver a entrar (~910 ARS sobre 69.600).

### La meta

**400.000 pesos, medidos en pesos del 10/08/2026** — se ajusta por inflación, no es nominal.
Aporte de **30.000 por mes**.

| | |
|---|---|
| Avance | 14,5 % (58.018 de 400.000) |
| Cuándo aporta | primera semana de cada mes (días 1 al 7) |
| Próximo aporte | 1 al 7 de septiembre de 2026 |
| Plazo con aporte ajustado por inflación | 12 meses |
| Plazo con aporte fijo en 30.000 | 13 meses |
| Meta nominal estimada | ≈ 517.440 ARS |

Supuesto de inflación: **2,0 % mensual** (REM del BCRA, junio 2026). Último dato real del
INDEC: 1,9 % mensual, 33,5 % interanual (junio 2026).

**Regla mensual:** cuando el INDEC publica el IPC (alrededor del día 13), actualizar el bloque
`meta.inflacion` de `posicion.json` con el dato real y recalcular la meta nominal.

## Automatización

Una tarea del Programador de tareas de Windows llamada **«Bitacora NVDA - reporte diario»**
ejecuta `reporte-diario.ps1` los días hábiles a las **17:35**. Corre como usuario común, sin
privilegios elevados, y con recuperación si la compu estuvo apagada.

```powershell
Get-ScheduledTaskInfo -TaskName 'Bitacora NVDA - reporte diario'   # cuándo corrió / cuándo corre
Start-ScheduledTask    -TaskName 'Bitacora NVDA - reporte diario'  # correrla ahora
Disable-ScheduledTask  -TaskName 'Bitacora NVDA - reporte diario'  # apagarla
Unregister-ScheduledTask -TaskName 'Bitacora NVDA - reporte diario' -Confirm:$false  # borrarla
```

**Trampa técnica ya resuelta, no volver a pisarla:** el prompt se le pasa a Claude por
*entrada estándar*, no como argumento de línea de comandos. Si se pasa como argumento, Windows
lo parte en palabras sueltas y Claude recibe sólo la primera. Por el mismo motivo la lista de
herramientas va separada por comas, no por espacios.

### Limitación conocida: el código de salida miente

El script de PowerShell que lanza a Claude **muere al final** con
`STATUS_CONTROL_C_EXIT` (`0xC000013A`). Claude Code es una app de terminal y, al salir,
dispara un evento de consola que se propaga y mata al proceso padre.

**El reporte se genera bien igual.** Se probó tres veces: las tres actualizaron el CSV,
regeneraron el dashboard y republicaron sobre la URL correcta. Lo único que se pierde son las
líneas finales del log y el código de salida.

Se intentaron cuatro arreglos sin éxito: llamar a node directo en vez de `claude.cmd`, usar
`System.Diagnostics.Process` en vez de `Start-Process`, ignorar CTRL+C con
`SetConsoleCtrlHandler`, y pedirle a Claude que escribiera su propia línea de cierre.

**Por eso NO hay que usar el log ni el `LastTaskResult` para saber si anduvo.** Los
indicadores confiables son:

1. **La última fila de `historial.csv`** — si tiene la fecha de hoy, corrió.
2. **La fecha del dashboard** — dice siempre cuándo se actualizó por última vez.
3. **El aviso automático** — si falta la rueda anterior, la corrida siguiente lo escribe en el
   log al arrancar. Un día perdido no pasa desapercibido más de 24 horas.

```powershell
# ¿Corrió hoy?
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

4. **Agregar una fila a `historial.csv`.** El campo `estado` es `cierre` para las corridas de
   después de las 17:00, `intradiario` si se tomó con el mercado abierto. Si ya existe una
   fila de hoy en estado `intradiario`, **reemplazarla** — nunca duplicar el día. Las filas de
   días anteriores no se tocan.

5. **Regenerar `dashboard.html`** con los datos nuevos, manteniendo la estructura y el diseño:
   masthead → resultado → los dos motores → rango del día → contexto de NVIDIA → costos →
   objetivos → nota del día → pendientes → historial → pie. Actualizar el contador de «Día N»,
   el de registros, y la posición del marcador «Hoy» en el termómetro de objetivos.

6. **Republicar el dashboard** al mismo link, pasando la URL de arriba como parámetro `url` de
   la herramienta Artifact. El link nunca cambia.

## Reglas de contenido

- **El número principal es el resultado REAL** (neto de la comisión de venta), no la ganancia
  en papel. Mostrar la ganancia en papel como dato secundario, aclarando que es lo que muestra
  la app del broker.
- **Separar siempre los dos motores.** Cuánto del movimiento vino de NVIDIA y cuánto del
  dólar. Es el punto del proyecto.
- **Avisar si se cruza un disparador** (17.520 o 12.410) o si se acerca a menos del 3 %.
- **Los días 1 al 7 de cada mes, recordar el aporte de 30.000** en un bloque destacado arriba
  del tablero, y avisar si todavía no se registró. Es la variable que más pesa en el plan.
  Recordar también que conviene subirlo con la inflación (ver `meta.inflacion`), o el plan se
  estira de 12 a 13 meses.
- **No recomendar comprar ni vender.** El tablero informa y compara contra los objetivos que
  Francisco ya fijó. La decisión es suya.
- **Si un dato no se consigue, decirlo.** Dejar el campo vacío y aclararlo en la nota. Nunca
  estimar un precio ni completar con el del día anterior como si fuera de hoy.
- **La nota del día en criollo**, dos o tres párrafos, explicando qué pasó y por qué.
- Días sin rueda (feriados, fin de semana): no se agrega fila.

## Pendientes

- [ ] Cargar el IPC de julio cuando salga (13/08) y recalcular la meta nominal.
- [ ] Con ~2 semanas de datos, agregar el gráfico de evolución al dashboard.
- [x] Comisión real confirmada (0,5 %).
- [x] Objetivos de salida definidos, con regla de reingreso.
- [x] Meta de acumulación definida (400.000 en pesos de hoy, 30.000/mes).
- [x] Automatizar con el Programador de tareas de Windows.

## Fechas a tener en cuenta

- **13/08/2026** — INDEC publica el IPC de julio.
- **26/08/2026** — NVIDIA presenta resultados trimestrales.
- **~ago/sep 2027** — fecha estimada de llegada a la meta.
