import pathlib, shutil
src = pathlib.Path(__file__).resolve().parent.parent / 'icons'
def lg(i, stops, h=False):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{i}" x1="0" y1="0" x2="{1 if h else 0}" y2="{0 if h else 1}">{s}</linearGradient>'
G = '<radialGradient id="ground" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#000" stop-opacity=".38"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>'
GROUND = '<ellipse cx="128" cy="228" rx="100" ry="11" fill="url(#ground)"/>'
GLYPH = {
 "documents": '<path d="M108 130a5 5 0 0 1 5-5h22l13 13v38a5 5 0 0 1-5 5h-30a5 5 0 0 1-5-5z"/><g fill="{bg}"><rect x="115" y="146" width="26" height="5" rx="2.500"/><rect x="115" y="156" width="26" height="5" rx="2.500"/><rect x="115" y="166" width="16" height="5" rx="2.500"/></g>',
 "downloads": '<path d="M120 128h16v24h14l-22 26-22-26h14z"/>',
 "pictures": '<circle cx="146" cy="138" r="8"/><path d="M100 180l22-32 14 18 8-10 14 24z"/>',
 "music": '<path d="M120 132l30-8v38a10 9 0 1 1-8-8.800V139l-14 3.600V170a10 9 0 1 1-8-8.800z"/>',
}
def patch(glyph, dy=0, rot=-5):
    if glyph is None:
        return f'<g transform="translate(46 {22+dy}) rotate(-8 140 150)"><rect x="118" y="130" width="46" height="42" rx="6" fill="#FA1D3C"/><rect x="123" y="135" width="36" height="32" rx="3" fill="none" stroke="#fff" stroke-width="3" stroke-dasharray="7 6"/></g>'
    g = GLYPH[glyph].replace("{bg}", "#FA1D3C")
    return (f'<g transform="translate(0 {dy}) rotate({rot} 128 156)"><rect x="84" y="116" width="88" height="80" rx="9" fill="#FA1D3C"/>'
            f'<rect x="90" y="122" width="76" height="68" rx="5" fill="none" stroke="#fff" stroke-width="3" stroke-dasharray="7 6" opacity=".85"/><g fill="#fff">{g}</g></g>')
def stencil(glyph):
    if glyph is None:
        return '<g fill="#3B2410" opacity=".7"><rect x="150" y="150" width="44" height="8" rx="2"/><rect x="150" y="164" width="30" height="8" rx="2"/></g>'
    g = GLYPH[glyph].replace("{bg}", "#C99552")
    return f'<g fill="#3B2410" opacity=".8" transform="translate(-51 -70) scale(1.4)">{g}</g>'

def suitcase(glyph):
    d = lg("b", [(0, "#A7653A"), (1, "#6B3A1C")]) + lg("m", [(0, "#F6D77A"), (1, "#C99522")])
    body = ('<path d="M96 76V60a16 16 0 0 1 16-16h32a16 16 0 0 1 16 16v16" fill="none" stroke="#3B2410" stroke-width="12" stroke-linecap="round"/>'
      '<rect x="22" y="72" width="212" height="144" rx="20" fill="url(#b)"/><rect x="38" y="74" width="180" height="3" rx="1.500" fill="#E3A877" opacity=".7"/>'
      '<path d="M22 100V92a20 20 0 0 1 20-20h8zM234 100V92a20 20 0 0 0-20-20h-8zM22 188v8a20 20 0 0 0 20 20h8zM234 188v8a20 20 0 0 1-20 20h-8z" fill="#3B2410"/>'
      '<rect x="56" y="72" width="18" height="144" fill="#3B2410"/><rect x="182" y="72" width="18" height="144" fill="#3B2410"/>'
      '<rect x="52" y="100" width="26" height="20" rx="4" fill="url(#m)"/><rect x="178" y="100" width="26" height="20" rx="4" fill="url(#m)"/>'
      '<rect x="22" y="190" width="212" height="26" rx="20" fill="#2B190A" opacity=".18"/>')
    return d, body + patch(glyph, 4)
def lunchbox(glyph):
    d = lg("b", [(0, "#5E7FA8"), (1, "#36527A")]) + lg("l", [(0, "#86A6CC"), (1, "#5E7FA8")]) + lg("m", [(0, "#F4F6FA"), (1, "#AEB7C6")])
    body = ('<path d="M92 62V50a14 14 0 0 1 14-14h44a14 14 0 0 1 14 14v12" fill="none" stroke="url(#m)" stroke-width="10" stroke-linecap="round"/>'
      '<path d="M28 112V98a44 44 0 0 1 44-44h112a44 44 0 0 1 44 44v14z" fill="url(#l)"/><path d="M52 68c10-8 20-11 30-11h92" stroke="#D5E4F5" stroke-width="4" stroke-linecap="round" fill="none" opacity=".7"/>'
      '<rect x="28" y="108" width="200" height="108" rx="16" fill="url(#b)"/><rect x="28" y="106" width="200" height="8" fill="#2A4064"/>'
      '<rect x="112" y="96" width="32" height="28" rx="6" fill="url(#m)"/><rect x="120" y="104" width="16" height="6" rx="3" fill="#6B768B"/>'
      '<g fill="#D5E4F5" opacity=".8"><circle cx="44" cy="124" r="4"/><circle cx="212" cy="124" r="4"/><circle cx="44" cy="200" r="4"/><circle cx="212" cy="200" r="4"/></g>'
      '<rect x="28" y="192" width="200" height="24" rx="16" fill="#14223A" opacity=".2"/>')
    return d, body + patch(glyph, 10, 0)
def sack(glyph):
    d = lg("b", [(0, "#E2CB98"), (1, "#A88A52")])
    weave = "".join(f'<path d="M{x} 96V212" stroke="#7A6233" stroke-width="2" opacity=".16"/>' for x in range(52, 212, 12)) + "".join(f'<path d="M40 {y}H216" stroke="#7A6233" stroke-width="2" opacity=".12"/>' for y in range(108, 212, 12))
    shape = 'M70 216c-30 0-42-40-30-86 8-28 36-36 58-48h60c22 12 50 20 58 48 12 46 0 86-30 86z'
    body = ('<path d="M92 66c8-18 16-26 22-28 4 8 10 10 14 2 4 8 10 6 14-2 6 2 14 10 22 28z" fill="#CDB480"/>'
      f'<path d="{shape}" fill="url(#b)"/><clipPath id="c"><path d="{shape}"/></clipPath><g clip-path="url(#c)">{weave}</g>'
      '<rect x="88" y="64" width="80" height="18" rx="9" fill="#8A5E34"/><path d="M96 70h64" stroke="#C99A62" stroke-width="3" stroke-linecap="round"/>'
      '<path d="M160 76c14 6 20 16 16 26M166 74c18 2 28 10 28 20" stroke="#8A5E34" stroke-width="6" stroke-linecap="round" fill="none"/>'
      '<path d="M56 130c-8 22-8 48 2 66" stroke="#FFF3D0" stroke-width="6" stroke-linecap="round" fill="none" opacity=".5"/>')
    return d, body + patch(glyph, 2)
def crate(glyph):
    d = lg("b", [(0, "#E2B273"), (1, "#BC8443")]) + lg("p", [(0, "#B98142"), (1, "#8A5A28")], True)
    planks = "".join(f'<rect x="30" y="{y}" width="196" height="30" rx="3" fill="url(#b)"/><rect x="34" y="{y+2}" width="188" height="3" rx="1.500" fill="#F6D9A8" opacity=".6"/>' for y in (74, 110, 146, 182))
    body = ('<rect x="26" y="70" width="204" height="146" rx="6" fill="#4A2D14"/>' + planks
      + '<rect x="26" y="70" width="26" height="146" rx="4" fill="url(#p)"/><rect x="204" y="70" width="26" height="146" rx="4" fill="url(#p)"/>'
      + "".join(f'<circle cx="{x}" cy="{y}" r="3.500" fill="#4A2D14"/>' for x in (39, 217) for y in (89, 125, 161, 197)))
    return d, body + stencil(glyph)

concepts = {"2-suitcase": suitcase, "3-lunchbox": lunchbox, "4-sack": sack, "5-crate": crate}
names = ["folder", "documents", "downloads", "pictures", "music"]
here = pathlib.Path(__file__).resolve().parent
out = here / "1-cardboard"; out.mkdir(exist_ok=True)
for n in names: shutil.copy(src / f"{n}.svg", out / f"{n}.svg")
for concept, draw in concepts.items():
    out = here / concept; out.mkdir(exist_ok=True)
    for n in names:
        defs, body = draw(None if n == "folder" else n)
        (out / f"{n}.svg").write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><defs>{G}{defs}</defs>{GROUND}{body}</svg>')
print("ok")
