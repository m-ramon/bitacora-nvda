# -*- coding: utf-8 -*-
"""Genera el <tbody> del historial del tablero desde historial.csv + la geometria del dia."""
import csv, json

def es(x, dec=0):
    """Formatea un numero al estilo argentino: miles con punto, decimales con coma."""
    s = ("%%.%df" % dec) % abs(float(x))
    if dec:
        ent, frac = s.split(".")
    else:
        ent, frac = s, ""
    grupos = []
    while len(ent) > 3:
        grupos.insert(0, ent[-3:]); ent = ent[:-3]
    grupos.insert(0, ent)
    out = ".".join(grupos)
    if dec:
        out += "," + frac
    return ("-" if float(x) < 0 else "") + out

def signo(x, dec=2, pct=True):
    v = float(x)
    cls = "pos" if v > 0 else ("neg" if v < 0 else "")
    txt = ("+" if v > 0 else ("−" if v < 0 else "")) + es(abs(v), dec) + (" %" if pct else "")
    return cls, txt

rows = list(csv.DictReader(open("historial.csv", encoding="utf-8")))

trs = []
for r in rows:
    d = r["fecha"][8:10] + "/" + r["fecha"][5:7]
    c_cdr, t_cdr = signo(r["cdr_var_pct"])
    c_nv, t_nv = signo(r["nvda_var_pct"])
    c_res, t_res = signo(r["resultado"] if "resultado" in r else 0)
    res = float(r["valor_pos_ars"]) * (1 - 0.00655) - 58017.54
    c_res = "pos" if res > 0 else "neg"
    t_res = ("+" if res > 0 else "−") + es(abs(res), 0)
    trs.append(
        "          <tr>\n"
        "            <td>%s</td>\n"
        "            <td>%s</td>\n"
        "            <td class=\"%s\">%s</td>\n"
        "            <td>%s</td>\n"
        "            <td class=\"%s\">%s</td>\n"
        "            <td>%s</td>\n"
        "            <td>%s</td>\n"
        "            <td class=\"%s\">%s</td>\n"
        "          </tr>" % (
            d, es(r["cdr_ars"]), c_cdr, t_cdr, es(r["nvda_usd"], 2), c_nv, t_nv,
            es(r["ccl_implicito"], 2), es(r["valor_pos_ars"]), c_res, t_res))

open("tbody.html", "w", encoding="utf-8").write("\n".join(trs) + "\n")

# ---- geometria del dia ----
last = rows[-1]
cdr = float(last["cdr_ars"]); nv = float(last["nvda_usd"])
mn, mx = float(last["cdr_min"]), float(last["cdr_max"])
prev = rows[-2]
ccl, cclp = float(last["ccl_implicito"]), float(prev["ccl_implicito"])
pos = json.load(open("posicion.json", encoding="utf-8"))
lo, hi = pos["referencia"]["nvda_52s_min"], pos["referencia"]["nvda_52s_max"]

cdrv = (cdr / float(prev["cdr_ars"]) - 1) * 100
nvv = (nv / float(prev["nvda_usd"]) - 1) * 100
cclv = (ccl / cclp - 1) * 100

print("registros (filas de datos):", len(rows))
print()
print("MOTORES (escala +-3%%), width = |var|/3*50")
for n, v in (("NVDA", nvv), ("CCL", cclv), ("CDR", cdrv)):
    print("  %-5s %+7.4f %%  -> fill %s  width %.2f%%" % (
        n, v, "right" if v > 0 else "left", min(abs(v) / 3 * 50, 50)))
print()
print("RANGO DEL DIA  min %s max %s amplitud %s" % (es(mn), es(mx), es(mx - mn)))
print("  cierre %s -> left %.2f%%" % (es(cdr), (cdr - mn) / (mx - mn) * 100))
for k, p in (("compra 14.410", 14410), ("cierre prev %s" % es(prev["cdr_ars"]), float(prev["cdr_ars"]))):
    fuera = "FUERA DE PISTA (por debajo del minimo)" if p < mn else (
        "FUERA DE PISTA (por encima del maximo)" if p > mx else "left %.2f%%" % ((p - mn) / (mx - mn) * 100))
    print("  %s -> %s" % (k, fuera))
print()
print("52 SEMANAS  %s - %s" % (es(lo, 2), es(hi, 2)))
print("  NVDA %s -> left %.2f%%" % (es(nv, 2), (nv - lo) / (hi - lo) * 100))
print("  desde el maximo %+.2f%%   desde el minimo %+.2f%%" % ((nv / hi - 1) * 100, (nv / lo - 1) * 100))
print()
print("TERMOMETRO (12.410 - 17.520)")
print("  hoy %s -> left %.2f%%" % (es(cdr), (cdr - 12410) / 5110 * 100))
print("  equilibrio 14.600 -> 42,86%% (fijo)")
print()
print("RESULTADO")
vpos = 4 * cdr
print("  valor posicion %s   neto de venta %s   resultado %+.0f (%.2f%%)" % (
    es(vpos), es(vpos * (1 - 0.00655)), vpos * (1 - 0.00655) - 58017.54,
    (vpos * (1 - 0.00655) - 58017.54) / 58017.54 * 100))
print("  comision de venta %.0f" % (vpos * 0.00655))
print("  en papel %+.0f (%.2f%%)   posicion en USD %.2f" % (
    vpos - 57640, (vpos - 57640) / 57640 * 100, 0.166667 * nv))
print()
print("DISPARADORES  gana %+.2f%%   equilibrio %+.2f%%   pierde %+.2f%%" % (
    (17520 / cdr - 1) * 100, (14600 / cdr - 1) * 100, (12410 / cdr - 1) * 100))
print("DESCOMPOSICION  %.5f x %.5f = %.5f  -> %+.2f%% (observado %+.2f%%)" % (
    1 + nvv / 100, 1 + cclv / 100, (1 + nvv / 100) * (1 + cclv / 100),
    ((1 + nvv / 100) * (1 + cclv / 100) - 1) * 100, cdrv))
