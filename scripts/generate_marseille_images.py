#!/usr/bin/env python3
# AVISO (2026-09-26): este generador producia las cartas placeholder que resultaron estar
# practicamente en blanco (56 de 78 identicas entre si). EL MAZO REAL YA NO SE GENERA AQUI:
# los marseille_*.png del repositorio son las cartas del PDF aportado por el usuario, con
# procedencia y huellas en scripts/deck-assets/deck-manifest.json.
# Volver a ejecutar este script SOBRESCRIBE el mazo real con placeholders.
"""Genera las 78 imágenes del mazo Tarot de Marsella (estilo xilografía).
Salida: TarotContent/Resources/marseille_<imageName>.png  (512x824)
Paleta clásica de Marsella: crema, azul, rojo, oro, tinta oscura.
"""
import json
import os
import math
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "TarotContent", "Resources")

W, H = 512, 824
CREAM = (243, 233, 210)
BLUE = (44, 95, 138)
RED = (196, 59, 47)
GOLD = (232, 179, 60)
INK = (58, 42, 30)
SKIN = (240, 220, 190)

INK_W = 6

def font(size, bold=False):
    for name in (["Georgia Bold", "Georgia"] if bold else ["Georgia", "Times New Roman"]):
        try:
            return ImageFont.truetype(f"{name}.ttf", size)
        except OSError:
            pass
    return ImageFont.load_default()

def new_card():
    img = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(img)
    # Marco doble estilo Marsella
    d.rectangle([14, 14, W-14, H-14], outline=INK, width=8)
    d.rectangle([30, 30, W-30, H-30], outline=INK, width=3)
    # Esquinas doradas
    for cx, cy in ((22, 22), (W-22, 22), (22, H-22), (W-22, H-22)):
        d.ellipse([cx-8, cy-8, cx+8, cy+8], fill=GOLD, outline=INK, width=3)
    return img, d

def title_banner(d, text, color=BLUE):
    """Banda inferior con el nombre de la carta."""
    y0 = H - 96
    d.rectangle([34, y0, W-34, H-34], fill=color, outline=INK, width=5)
    d.rectangle([42, y0+8, W-42, H-42], outline=GOLD, width=2)
    f = font(30, bold=True)
    bb = d.textbbox((0, 0), text, font=f)
    tw = bb[2] - bb[0]
    x = (W - tw) // 2
    # Sombra + texto
    d.text((x+2, y0 + (96 - (bb[3]-bb[1]))//2 - bb[1] + 2), text, font=f, fill=INK)
    d.text((x, y0 + (96 - (bb[3]-bb[1]))//2 - bb[1]), text, font=f, fill=GOLD)

def numeral(d, text, color=RED):
    f = font(36, bold=True)
    bb = d.textbbox((0, 0), text, font=f)
    d.text(((W - (bb[2]-bb[0]))//2 + 2, 44), text, font=f, fill=INK)
    d.text(((W - (bb[2]-bb[0]))//2, 42), text, font=f, fill=color)

def star(d, cx, cy, r, fill=GOLD, points=8):
    pts = []
    for i in range(points * 2):
        rad = r if i % 2 == 0 else r * 0.45
        a = math.pi * i / points - math.pi / 2
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    d.polygon(pts, fill=fill, outline=INK, width=3)

def crown(d, cx, cy, w, h, fill=GOLD):
    pts = [(cx - w//2, cy + h//2), (cx - w//2, cy), (cx - w//3, cy + h//3),
           (cx - w//6, cy - h//2), (cx, cy + h//4), (cx + w//6, cy - h//2),
           (cx + w//3, cy + h//3), (cx + w//2, cy), (cx + w//2, cy + h//2)]
    d.polygon(pts, fill=fill, outline=INK, width=3)

def face(d, cx, cy, r, fill=SKIN):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=INK, width=3)
    er = max(2, r // 9)
    d.ellipse([cx-r*0.45-er, cy-r*0.2-er, cx-r*0.45+er, cy-r*0.2+er], fill=INK)
    d.ellipse([cx+r*0.45-er, cy-r*0.2-er, cx+r*0.45+er, cy-r*0.2+er], fill=INK)
    d.arc([cx-r*0.4, cy-r*0.1, cx+r*0.4, cy+r*0.55], 20, 160, fill=INK, width=3)

def robe(d, cx, top, w, h, fill):
    d.polygon([(cx-w//2, top+h), (cx-w//3, top), (cx+w//3, top), (cx+w//2, top+h)],
              fill=fill, outline=INK, width=3)

def sun_face(d, cx, cy, r, fill=GOLD):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=INK, width=4)
    for i in range(16):
        a = 2 * math.pi * i / 16
        x1, y1 = cx + (r+10) * math.cos(a), cy + (r+10) * math.sin(a)
        x2, y2 = cx + (r+34) * math.cos(a), cy + (r+34) * math.sin(a)
        d.line([x1, y1, x2, y2], fill=INK, width=5)
    face(d, cx, cy, int(r*0.55))

# ── Escenas emblemáticas de los Arcanos Mayores ─────────────────────────────

def scene_fool(d):  # El Loco
    robe(d, W//2, 300, 190, 240, BLUE)
    face(d, W//2, 260, 44)
    crown(d, W//2, 205, 90, 44, GOLD)
    d.line([W//2+70, 320, W//2+150, 220], fill=INK, width=6)
    star(d, W//2+150, 205, 22)
    d.rectangle([W//2-160, 540, W//2+160, 560], fill=INK)
    d.ellipse([W//2-190, 560, W//2-90, 660], fill=RED, outline=INK, width=3)

def scene_magician(d):  # El Mago
    robe(d, W//2, 300, 190, 250, RED)
    face(d, W//2, 260, 44)
    crown(d, W//2, 205, 100, 40, GOLD)
    star(d, W//2, 560, 46, GOLD, points=8)
    d.rectangle([W//2+60, 330, W//2+140, 350], fill=INK)
    d.ellipse([W//2-150, 300, W//2-90, 360], fill=BLUE, outline=INK, width=3)

def scene_papess(d):  # La Papisa
    robe(d, W//2, 300, 200, 260, BLUE)
    face(d, W//2, 260, 44)
    crown(d, W//2, 200, 110, 50, GOLD)
    d.rectangle([W//2-120, 470, W//2+120, 560], outline=INK, width=5)
    d.ellipse([W//2-70, 420, W//2+70, 520], outline=INK, width=4)

def scene_empress(d):  # La Emperatriz
    robe(d, W//2, 310, 210, 240, RED)
    face(d, W//2, 265, 44)
    crown(d, W//2, 205, 120, 55, GOLD)
    star(d, W//2, 170, 20)
    star(d, W//2-140, 240, 16)
    star(d, W//2+140, 240, 16)

def scene_emperor(d):  # El Emperador
    robe(d, W//2, 310, 210, 240, BLUE)
    face(d, W//2, 265, 44)
    crown(d, W//2, 200, 130, 60, GOLD)
    d.line([W//2-130, 350, W//2-60, 350], fill=INK, width=8)
    d.polygon([(W//2-130, 350), (W//2-110, 320), (W//2-90, 350)], fill=GOLD, outline=INK)

def scene_pope(d):  # El Papa
    robe(d, W//2, 300, 210, 260, RED)
    face(d, W//2, 260, 44)
    crown(d, W//2, 200, 110, 60, GOLD)
    for dx in (-90, 0, 90):
        star(d, W//2+dx, 480, 18)

def scene_lovers(d):  # El Enamorado
    robe(d, W//2-90, 330, 140, 210, BLUE)
    robe(d, W//2+90, 330, 140, 210, RED)
    face(d, W//2-90, 290, 36)
    face(d, W//2+90, 290, 36)
    crown(d, W//2, 200, 100, 50, GOLD)
    face(d, W//2, 250, 34)
    star(d, W//2, 160, 24)

def scene_chariot(d):  # El Carro
    d.rectangle([W//2-150, 430, W//2+150, 530], fill=BLUE, outline=INK, width=5)
    robe(d, W//2, 300, 150, 130, RED)
    face(d, W//2, 255, 40)
    crown(d, W//2, 200, 100, 45, GOLD)
    for dx in (-110, 110):
        d.ellipse([W//2+dx-35, 530, W//2+dx+35, 600], fill=INK, outline=GOLD, width=4)
    star(d, W//2, 160, 20)

def scene_justice(d):  # La Justicia
    robe(d, W//2, 300, 190, 250, RED)
    face(d, W//2, 260, 44)
    crown(d, W//2, 205, 100, 45, GOLD)
    d.line([W//2-160, 330, W//2-60, 330], fill=INK, width=5)
    d.line([W//2-110, 300, W//2-110, 420], fill=INK, width=5)
    d.rectangle([W//2-150, 420, W//2-70, 445], fill=GOLD, outline=INK, width=3)
    d.ellipse([W//2+60, 340, W//2+130, 410], outline=INK, width=6)

def scene_hermit(d):  # El Ermitaño
    robe(d, W//2, 300, 180, 260, BLUE)
    face(d, W//2, 260, 44)
    crown(d, W//2, 205, 90, 40, GOLD)
    d.line([W//2+70, 320, W//2+70, 560], fill=INK, width=6)
    d.ellipse([W//2+45, 240, W//2+95, 290], fill=GOLD, outline=INK, width=3)

def scene_wheel(d):  # La Rueda de la Fortuna
    cx, cy = W//2, 400
    d.ellipse([cx-150, cy-150, cx+150, cy+150], fill=BLUE, outline=INK, width=6)
    d.ellipse([cx-100, cy-100, cx+100, cy+100], fill=CREAM, outline=INK, width=4)
    d.ellipse([cx-40, cy-40, cx+40, cy+40], fill=RED, outline=INK, width=4)
    for i in range(8):
        a = math.pi * i / 4
        d.line([cx+40*math.cos(a), cy+40*math.sin(a), cx+100*math.cos(a), cy+100*math.sin(a)], fill=INK, width=4)
    star(d, cx, cy, 20)

def scene_strength(d):  # La Fuerza
    robe(d, W//2, 320, 180, 230, RED)
    face(d, W//2, 275, 42)
    crown(d, W//2, 220, 100, 45, GOLD)
    d.ellipse([W//2-190, 480, W//2-60, 590], outline=INK, width=6)
    d.ellipse([W//2-150, 510, W//2-100, 560], fill=BLUE, outline=INK, width=3)
    d.line([W//2+60, 330, W//2+150, 380], fill=INK, width=5)

def scene_hanged(d):  # El Colgado
    d.rectangle([W//2-160, 180, W//2+160, 200], fill=INK)
    robe(d, W//2, 330, 150, 200, BLUE)
    face(d, W//2, 300, 42)
    d.line([W//2-75, 360, W//2-75, 520], fill=INK, width=5)
    d.line([W//2+75, 360, W//2+75, 520], fill=INK, width=5)
    star(d, W//2-75, 545, 16)
    star(d, W//2+75, 545, 16)

def scene_death(d):  # La Muerte
    robe(d, W//2, 290, 180, 280, INK)
    face(d, W//2, 250, 42, fill=CREAM)
    for dx in (-20, -7, 7, 20):
        d.ellipse([W//2+dx-4, 242, W//2+dx+4, 254], fill=INK)
    d.line([W//2+60, 300, W//2+170, 200], fill=INK, width=6)
    d.polygon([(W//2+170, 200), (W//2+130, 210), (W//2+165, 245)], fill=CREAM, outline=INK)
    star(d, W//2-140, 500, 18)

def scene_temperance(d):  # La Templanza
    robe(d, W//2, 300, 190, 260, BLUE)
    face(d, W//2, 260, 44)
    crown(d, W//2, 205, 100, 45, GOLD)
    d.line([W//2-70, 360, W//2-150, 430], fill=INK, width=5)
    d.line([W//2+70, 360, W//2+150, 430], fill=INK, width=5)
    d.ellipse([W//2-170, 430, W//2-110, 490], fill=GOLD, outline=INK, width=3)
    d.ellipse([W//2+110, 430, W//2+170, 490], fill=GOLD, outline=INK, width=3)
    d.arc([W//2-80, 470, W//2+80, 570], 200, 340, fill=BLUE, width=6)

def scene_devil(d):  # El Diablo
    robe(d, W//2, 310, 200, 240, RED)
    face(d, W//2, 265, 44, fill=RED)
    d.polygon([(W//2-60, 235), (W//2-95, 185), (W//2-30, 220)], fill=INK)
    d.polygon([(W//2+60, 235), (W//2+95, 185), (W//2+30, 220)], fill=INK)
    for dx in (-130, 130):
        d.ellipse([W//2+dx-30, 470, W//2+dx+30, 530], outline=INK, width=5)
    star(d, W//2, 160, 22, fill=RED)

def scene_tower(d):  # La Torre
    d.rectangle([W//2-70, 260, W//2+70, 600], fill=BLUE, outline=INK, width=5)
    d.rectangle([W//2-90, 220, W//2+90, 260], fill=GOLD, outline=INK, width=4)
    crown(d, W//2, 200, 110, 45, GOLD)
    for i, y in enumerate(range(320, 560, 60)):
        d.polygon([(W//2-60 + (i%2)*30, y), (W//2+40, y+45), (W//2-20, y+55)], fill=RED, outline=INK, width=2)
    d.polygon([(W//2+150, 180), (W//2+90, 330), (W//2+140, 300), (W//2+95, 420)], fill=GOLD, outline=INK, width=3)

def scene_star(d):  # La Estrella
    robe(d, W//2, 340, 170, 220, BLUE)
    face(d, W//2, 300, 42)
    star(d, W//2, 200, 52, GOLD, points=8)
    for dx, dy in ((-130, 260), (130, 260), (-90, 180), (90, 180), (0, 120)):
        star(d, W//2+dx, dy, 16)
    d.ellipse([W//2-40, 560, W//2+40, 620], fill=BLUE, outline=INK, width=4)

def scene_moon(d):  # La Luna
    cx, cy = W//2, 260
    d.ellipse([cx-110, cy-110, cx+110, cy+110], fill=GOLD, outline=INK, width=5)
    face(d, cx, cy, 62)
    d.ellipse([cx-150, cy-150, cx+150, cy+150], outline=BLUE, width=4)
    robe(d, W//2-110, 430, 120, 150, BLUE)
    robe(d, W//2+110, 430, 120, 150, RED)
    d.polygon([(cx-160, 600), (cx-120, 520), (cx-80, 600)], fill=BLUE, outline=INK, width=3)
    d.polygon([(cx+80, 600), (cx+120, 520), (cx+160, 600)], fill=RED, outline=INK, width=3)

def scene_sun(d):  # El Sol
    sun_face(d, W//2, 250, 70)
    robe(d, W//2-80, 400, 120, 170, RED)
    robe(d, W//2+80, 400, 120, 170, BLUE)
    face(d, W//2-80, 370, 30)
    face(d, W//2+80, 370, 30)
    d.line([W//2-80, 420, W//2+80, 420], fill=INK, width=5)

def scene_judgement(d):  # El Juicio
    robe(d, W//2-100, 420, 120, 160, BLUE)
    robe(d, W//2+100, 420, 120, 160, RED)
    face(d, W//2-100, 385, 30)
    face(d, W//2+100, 385, 30)
    d.rectangle([W//2-140, 200, W//2+140, 240], fill=CREAM, outline=INK, width=5)
    d.arc([W//2-60, 240, W//2+60, 380], 180, 360, fill=GOLD, width=8)
    d.line([W//2-30, 250, W//2-30, 340], fill=INK, width=4)
    d.line([W//2+30, 250, W//2+30, 340], fill=INK, width=4)

def scene_world(d):  # El Mundo
    d.ellipse([W//2-150, 250, W//2+150, 550], outline=GOLD, width=10)
    robe(d, W//2, 330, 140, 180, BLUE)
    face(d, W//2, 295, 38)
    star(d, W//2, 210, 26)
    for dx, dy in ((-160, 280), (160, 280), (-160, 520), (160, 520)):
        star(d, W//2+dx, dy, 18)

# ── Símbolos de palos (Arcanos Menores) ─────────────────────────────────────

def pip_wand(d, cx, cy, h, fill=BLUE):
    d.rounded_rectangle([cx-9, cy-h//2, cx+9, cy+h//2], radius=4, fill=fill, outline=INK, width=3)
    d.ellipse([cx-14, cy-h//2-16, cx+14, cy-h//2+8], fill=GOLD, outline=INK, width=3)
    d.ellipse([cx-14, cy+h//2-8, cx+14, cy+h//2+16], fill=RED, outline=INK, width=3)

def pip_cup(d, cx, cy, s, fill=GOLD):
    d.pieslice([cx-s, cy-s, cx+s, cy+s], 180, 360, fill=fill, outline=INK, width=3)
    d.rectangle([cx-6, cy, cx+6, cy+s*0.7], fill=fill, outline=INK, width=2)
    d.rounded_rectangle([cx-s*0.6, cy+s*0.7, cx+s*0.6, cy+s*0.95], radius=5, fill=fill, outline=INK, width=3)

def pip_sword(d, cx, cy, h, fill=BLUE, down=False):
    if not down:
        d.polygon([(cx, cy-h//2), (cx-7, cy-h//2+26), (cx+7, cy-h//2+26)], fill=CREAM, outline=INK, width=2)
        d.rectangle([cx-4, cy-h//2+26, cx+4, cy+h//4], fill=CREAM, outline=INK, width=2)
        d.rectangle([cx-22, cy+h//4, cx+22, cy+h//4+10], fill=GOLD, outline=INK, width=2)
        d.rectangle([cx-5, cy+h//4+10, cx+5, cy+h//2], fill=fill, outline=INK, width=2)
    else:
        d.rectangle([cx-5, cy-h//2, cx+5, cy-h//2+h//4], fill=fill, outline=INK, width=2)
        d.rectangle([cx-22, cy-h//4-10, cx+22, cy-h//4], fill=GOLD, outline=INK, width=2)
        d.rectangle([cx-4, cy-h//4, cx+4, cy+h//2-26], fill=CREAM, outline=INK, width=2)
        d.polygon([(cx, cy+h//2), (cx-7, cy+h//2-26), (cx+7, cy+h//2-26)], fill=CREAM, outline=INK, width=2)

def pip_coin(d, cx, cy, r, fill=GOLD):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=INK, width=4)
    d.ellipse([cx-r*0.65, cy-r*0.65, cx+r*0.65, cy+r*0.65], outline=BLUE, width=3)
    d.line([cx-r*0.4, cy, cx+r*0.4, cy], fill=BLUE, width=3)
    d.line([cx, cy-r*0.4, cx, cy+r*0.4], fill=BLUE, width=3)

PIPS = {  # posiciones relativas (fracción del área útil)
    1: [(0.5, 0.5)],
    2: [(0.5, 0.3), (0.5, 0.7)],
    3: [(0.3, 0.28), (0.7, 0.28), (0.5, 0.62)],
    4: [(0.3, 0.3), (0.7, 0.3), (0.3, 0.7), (0.7, 0.7)],
    5: [(0.28, 0.28), (0.72, 0.28), (0.5, 0.5), (0.28, 0.72), (0.72, 0.72)],
    6: [(0.3, 0.22), (0.7, 0.22), (0.3, 0.5), (0.7, 0.5), (0.3, 0.78), (0.7, 0.78)],
    7: [(0.3, 0.2), (0.7, 0.2), (0.3, 0.45), (0.7, 0.45), (0.3, 0.7), (0.7, 0.7), (0.5, 0.32)],
    8: [(0.3, 0.18), (0.7, 0.18), (0.3, 0.42), (0.7, 0.42), (0.3, 0.62), (0.7, 0.62), (0.3, 0.84), (0.7, 0.84)],
    9: [(0.25, 0.2), (0.5, 0.2), (0.75, 0.2), (0.25, 0.5), (0.75, 0.5), (0.25, 0.8), (0.5, 0.8), (0.75, 0.8), (0.5, 0.5)],
    10: [(0.25, 0.16), (0.75, 0.16), (0.25, 0.38), (0.75, 0.38), (0.5, 0.27), (0.5, 0.5), (0.25, 0.62), (0.75, 0.62), (0.25, 0.84), (0.75, 0.84)],
}

def draw_pips(d, suit, count):
    area_top, area_bottom = 120, H - 130
    for i, (fx, fy) in enumerate(PIPS[count]):
        cx = 60 + fx * (W - 120)
        cy = area_top + fy * (area_bottom - area_top)
        alt = i % 2 == 1
        if suit == "wands":
            pip_wand(d, cx, cy, 120, BLUE if not alt else RED)
        elif suit == "cups":
            pip_cup(d, cx, cy, 42, GOLD if not alt else BLUE)
        elif suit == "swords":
            pip_sword(d, cx, cy, 130, BLUE if not alt else RED, down=suit_down(suit, alt))
        elif suit == "pentacles":
            pip_coin(d, cx, cy, 40, GOLD if not alt else RED)

def suit_down(suit, alt):
    return False

def court_figure(d, suit, kind):
    """Paje/Caballero/Reina/Rey — busto con corona o yelmo."""
    cy_head = 300
    robe(d, W//2, cy_head + 50, 220, 260, RED if kind in ("queen", "page") else BLUE)
    face(d, W//2, cy_head, 48)
    if kind == "king":
        crown(d, W//2, cy_head - 60, 130, 62, GOLD)
    elif kind == "queen":
        crown(d, W//2, cy_head - 60, 110, 52, GOLD)
        d.arc([W//2-60, cy_head-40, W//2+60, cy_head+60], 150, 390, fill=INK, width=5)
    elif kind == "knight":
        d.rounded_rectangle([W//2-46, cy_head-64, W//2+46, cy_head-18], radius=10, fill=BLUE, outline=INK, width=3)
        d.rectangle([W//2-30, cy_head-64, W//2+30, cy_head-74], fill=GOLD, outline=INK, width=2)
    else:  # page
        crown(d, W//2, cy_head - 58, 90, 40, RED)
    # Insignia del palo
    if suit == "wands":   pip_wand(d, W//2, cy_head + 190, 120, GOLD)
    elif suit == "cups":  pip_cup(d, W//2, cy_head + 170, 44)
    elif suit == "swords": pip_sword(d, W//2, cy_head + 190, 130, GOLD)
    elif suit == "pentacles": pip_coin(d, W//2, cy_head + 180, 42)

# ════════════════════════════════════════════════════════════════
# MAIN — carga cards.json y genera las 78 imágenes
# ════════════════════════════════════════════════════════════════

CARDS_JSON = os.path.join(HERE, "..", "TarotContent", "Resources", "cards.json")

def load_cards():
    with open(CARDS_JSON, encoding="utf-8") as f:
        data = json.load(f)
    cards = data["cards"] if isinstance(data, dict) else data
    # Solo arcanos con imageName explícito (los únicos que tienen arte propio)
    return [c for c in cards if c.get("imageName")]

def major_num(image_name):
    """Extrae el número del arcano mayor desde 'card_XX_...'."""
    try:
        return int(image_name.split("_")[1])
    except (IndexError, ValueError):
        return None

SUIT_KINDS = {  # rank -> (kind, numeral)
    11: ("page", "VALET"), 12: ("knight", "CAVALIER"),
    13: ("queen", "REINE"), 14: ("king", "ROI"),
}

def generate():
    cards = load_cards()
    os.makedirs(RES, exist_ok=True)
    made = 0
    for c in cards:
        img_name = c["imageName"]
        out = os.path.join(RES, f"marseille_{img_name}.png")
        if os.path.exists(out):
            continue
        img, d = new_card()
        suit = c.get("suit")            # wands/cups/swords/pentacles | None
        rank = c.get("rank")            # 1..14 en menores
        n = major_num(img_name)
        if suit is None and n is not None:
            scene_fn = SCENES.get(n)
            if scene_fn:
                scene_fn(d)
            else:
                generic_major(d, n)
            numeral(d, str(n) if n not in (0, 21) else ("0" if n == 0 else "XXI"))
            title_banner(d, c["name"].upper())
        elif suit and rank and rank <= 10:
            draw_pips(d, suit, rank)
            numeral(d, str(rank))
            title_banner(d, c["name"].upper())
        elif suit and rank and rank in SUIT_KINDS:
            kind, numeral_txt = SUIT_KINDS[rank]
            court_figure(d, suit, kind)
            numeral(d, numeral_txt)
            title_banner(d, c["name"].upper())
        else:
            generic_major(d, n if n is not None else 0)
            title_banner(d, c["name"].upper())
        img.save(out, "PNG")
        made += 1
    print(f"✦ Generadas {made} imágenes nuevas (marseille_*.png)")
    print(f"✦ Total esperado: {len(cards)} — revisa TarotContent/Resources/")

def generic_major(d, n):
    """Escena base para arcanos sin función dedicada."""
    d.rectangle([90, 140, W-90, H-220], fill=CREAM, outline=INK, width=3)
    sun_face(d, W//2, 300, 70)
    star(d, W//2, 520, 55)
    d.arc([120, 640, W-120, 780], 180, 360, fill=BLUE, width=6)

# ════════════════════════════════════════════════════════════════
# Tabla de escenas: número de arcano → función que dibuja la escena
# (Las funciones scene_* ya existen arriba; aquí se mapean a su número)
# ════════════════════════════════════════════════════════════════
SCENES = {
     0: scene_fool,
     1: scene_magician,
     2: scene_papess,
     3: scene_empress,
     4: scene_emperor,
     5: scene_pope,
     6: scene_lovers,
     7: scene_chariot,
     8: scene_strength,
     9: scene_hermit,
    10: scene_wheel,
    11: scene_justice,
    12: scene_hanged,
    13: scene_death,
    14: scene_temperance,
    15: scene_devil,
    16: scene_tower,
    17: scene_star,
    18: scene_moon,
    19: scene_sun,
    20: scene_judgement,
    21: scene_world,
}


if __name__ == "__main__":
    generate()


