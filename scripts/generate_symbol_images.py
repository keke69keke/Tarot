#!/usr/bin/env python3
"""
Genera las imágenes de los 10 símbolos universales del Atlas de Símbolos.

Estilo: medallón místico circular en la paleta exacta de la app
(TarotColors.swift) — fondo violeta nocturno, arte lineal lavanda "oro tarot",
inspirado en el simbolismo de las cartas Rider-Waite.

Salida: TarotContent/Resources/symbol_<id>.png (512×512)

Uso:  python3 scripts/generate_symbol_images.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Tamaño de trabajo (2x) y de salida — se reescala con LANCZOS para suavizar.
S = 1024
OUT = 512

OUTDIR = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "TarotContent", "Resources")
)

# ---------------------------------------------------------------- Paleta (TarotColors.swift)
IVORY = (242, 242, 230)
GOLD = (153, 133, 255)       # #9985FF  lavanda tarot
GOLD_HI = (199, 184, 255)    # highlight
GOLD_DEEP = (92, 71, 199)    # deep
BG_IN = (28, 20, 48)         # cardBase  (0.11, 0.08, 0.19)
BG_OUT = (15, 10, 33)        # background (0.06, 0.04, 0.13)

CX = CY = S // 2

# ---------------------------------------------------------------- Utilidades geométricas


def P(cx, cy, r, deg):
    """Punto polar (grados, 0°=derecha, 90°=abajo por coordenadas de imagen)."""
    a = math.radians(deg)
    return (cx + r * math.cos(a), cy + r * math.sin(a))


def P2(c, r, ang_rad):
    return (c[0] + r * math.cos(ang_rad), c[1] + r * math.sin(ang_rad))


def closed_line(d, pts, color, width):
    d.line(list(pts) + [pts[0]], fill=color, width=width, joint="curve")


def wave_pts(x1, x2, y, amp, periods, steps=60):
    return [(x1 + (x2 - x1) * t / steps, y + amp * math.sin(t / steps * periods * 2 * math.pi))
            for t in range(steps + 1)]


def radial_wave(c, r1, r2, deg, amp, periods, steps=48):
    """Rayo ondulado que avanza radialmente con vaivén perpendicular."""
    out = []
    for t in range(steps + 1):
        f = t / steps
        r = r1 + (r2 - r1) * f
        bx, by = P(c[0], c[1], r, deg)
        ox, oy = P(0, 0, 1, deg + 90)
        w = amp * math.sin(f * periods * 2 * math.pi)
        out.append((bx + ox * w, by + oy * w))
    return out


def mini_star(d, cx, cy, R, color, width):
    """Estrella de 4 puntas."""
    pts = [P(cx, cy, R if i % 2 == 0 else R * 0.30, -90 + i * 45) for i in range(8)]
    d.polygon(pts, outline=color, width=width)


def teardrop(d, cx, cy, r, color, width, up=True):
    """Gota: circulito con punta vertical."""
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=width)
    tip = cy - r * 2.2 if up else cy + r * 2.2
    off = r * 0.72
    yjoin = cy - off * 0.5 if up else cy + off * 0.5
    d.line([(cx - off, yjoin), (cx, tip), (cx + off, yjoin)], fill=color, width=width, joint="curve")


def leaf(d, center, length, width, angle, color, lw):
    """Hoja puntiaguda (elipse afinada en las puntas) rotada `angle` grados."""
    pts = []
    for t in range(41):
        f = t / 40
        rad = math.pi * 2 * f
        r = math.sin(rad) ** 0.65
        x = (f - 0.5) * 2 * length
        y = math.sin(rad) * width
        a = math.radians(angle)
        rx = x * math.cos(a) - y * math.sin(a)
        ry = x * math.sin(a) + y * math.cos(a)
        pts.append((center[0] + rx, center[1] + ry))
    closed_line(d, pts, color, lw)


def load_font(size):
    for p in (
        "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    ):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)

# ---------------------------------------------------------------- Lienzo y decoración


def load_font(size):
    for p in (
        "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/System/Library/Fonts/Supplemental/Georgia.ttf",
    ):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def text_center(d, xy, txt, font, color):
    box = d.textbbox((0, 0), txt, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text((xy[0] - w / 2 - box[0], xy[1] - h / 2 - box[1]), txt, font=font, fill=color)


def canvas():
    img = Image.new("RGB", (S, S), BG_OUT)
    grad = Image.radial_gradient("L").resize((S, S))  # 0 en el centro → 255 en bordes
    mask = grad.point(lambda v: 255 - v)
    img = Image.composite(Image.new("RGB", (S, S), BG_IN), img, mask)
    return img.convert("RGBA")


def decorate(img, seed):
    d = ImageDraw.Draw(img)
    # Anillo exterior + anillo punteado del medallón
    d.ellipse((CX - 486, CY - 486, CX + 486, CY + 486), outline=GOLD_DEEP, width=4)
    for deg in range(0, 360, 12):
        x, y = P(CX, CY, 456, deg)
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=GOLD_DEEP + (150,))
    # 4 diamantes cardinales
    for deg in (0, 90, 180, 270):
        x, y = P(CX, CY, 486, deg)
        d.polygon([(x, y - 11), (x + 11, y), (x, y + 11), (x - 11, y)], fill=GOLD)
    # Resplandor central
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((CX - 330, CY - 330, CX + 330, CY + 330), fill=GOLD_DEEP + (52,))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img.alpha_composite(glow)
    # Estrellas dispersas (deterministas)
    rnd = random.Random(seed)
    for _ in range(30):
        a = rnd.uniform(0, 360)
        r = rnd.uniform(140, 470)
        x, y = P(CX, CY, r, a)
        s = rnd.uniform(2.0, 4.5)
        d.ellipse((x - s, y - s, x + s, y + s), fill=IVORY + (rnd.randint(45, 110),))
    return d


def compose(img, art):
    """Glow + sombra + arte sobre el lienzo."""
    glow = art.filter(ImageFilter.GaussianBlur(24))
    img.alpha_composite(glow)
    img.alpha_composite(glow)  # doble pasada para intensidad
    a = art.getchannel("A").point(lambda v: v // 2)
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(sh, (0, 14))
    img.alpha_composite(art)


# ---------------------------------------------------------------- Símbolos


def draw_sun(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Disco solar con rostro sereno (estilo Rider-Waite)
    a.ellipse((CX - 140, CY - 140, CX + 140, CY + 140), fill=GOLD_DEEP + (70,), outline=GOLD, width=10)
    for ex in (-46, 46):
        a.arc((CX + ex - 22, CY - 62, CX + ex + 22, CY - 14), 200, 340, fill=GOLD_HI, width=8)
    a.line([(CX, CY - 12), (CX, CY + 26)], fill=GOLD_HI, width=7)
    a.arc((CX - 30, CY + 6, CX + 30, CY + 66), 15, 165, fill=GOLD_HI, width=8)
    # 8 rayos rectos + 8 ondulados
    for i in range(8):
        deg = i * 45
        tip = P(CX, CY, 250, deg)
        l, r = P(CX, CY, 150, deg - 7), P(CX, CY, 150, deg + 7)
        a.polygon([l, r, tip], fill=GOLD + (60,))
        a.line([l, tip, r], fill=GOLD, width=8, joint="curve")
        x, y = P(CX, CY, 272, deg)
        a.ellipse((x - 6, y - 6, x + 6, y + 6), fill=GOLD_HI)
        a.line(radial_wave((CX, CY), 152, 246, deg + 22.5, 16, 2.5), fill=GOLD_DEEP, width=7, joint="curve")
    return art


def draw_moon(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Creciente: intersección de dos círculos
    c1, r1, c2, r2 = (472, 512), 190, (620, 462), 158
    dist = math.hypot(c2[0] - c1[0], c2[1] - c1[1])
    aa = (dist * dist + r1 * r1 - r2 * r2) / (2 * dist)
    h = math.sqrt(max(0.0, r1 * r1 - aa * aa))
    ux, uy = (c2[0] - c1[0]) / dist, (c2[1] - c1[1]) / dist
    mx, my = c1[0] + aa * ux, c1[1] + aa * uy
    px, py = -uy, ux
    i1 = (mx + h * px, my + h * py)
    i2 = (mx - h * px, my - h * py)
    ang1 = math.atan2(i1[1] - c1[1], i1[0] - c1[0])
    ang2 = math.atan2(i2[1] - c1[1], i2[0] - c1[0])
    b1 = math.atan2(i1[1] - c2[1], i1[0] - c2[0])
    b2 = math.atan2(i2[1] - c2[1], i2[0] - c2[0])
    # Arco exterior sobre c1 (el punto de c1 más lejano de c2)
    far1 = math.atan2(c1[1] - c2[1], c1[0] - c2[0])

    def arc_between(c, r, af, at, via, n=120):
        span = (at - af) % (2 * math.pi)
        v = (via - af) % (2 * math.pi)
        if v <= span:
            return [P2(c, r, af + span * t / n) for t in range(n + 1)]
        span = (af - at) % (2 * math.pi)
        return [P2(c, r, af - span * t / n) for t in range(n + 1)]

    pts = arc_between(c1, r1, ang2, ang1, far1)
    # Arco interior sobre c2 (el punto de c2 más cercano a c1)
    near2 = math.atan2(c2[1] - c1[1], c2[0] - c1[0])
    pts += arc_between(c2, r2, b1, b2, near2)
    a.polygon(pts, fill=GOLD_DEEP + (60,))
    closed_line(a, pts, GOLD, 10)
    # Rostro soñador en el borde del creciente
    a.arc((392, 428, 444, 476), 190, 330, fill=GOLD_HI, width=7)
    a.arc((438, 532, 492, 582), 30, 160, fill=GOLD_HI, width=7)
    # Gotas que caen de la Luna
    for (x, y, r) in ((648, 620, 15), (700, 700, 13), (612, 730, 12)):
        teardrop(a, x, y, r, GOLD_DEEP, 6, up=False)
    mini_star(a, 250, 280, 30, GOLD_HI, 6)
    mini_star(a, 300, 190, 22, GOLD_DEEP, 5)
    return art


def draw_star(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Estrella grande de 8 puntas = dos de 4 puntas superpuestas
    big = [P(CX, CY, 270 if i % 2 == 0 else 64, -90 + i * 45) for i in range(8)]
    a.polygon(big, fill=GOLD_DEEP + (70,))
    closed_line(a, big, GOLD, 10)
    diag = [P(CX, CY, 148 if i % 2 == 0 else 42, -45 + i * 45) for i in range(8)]
    a.polygon(diag, fill=GOLD_HI + (80,))
    closed_line(a, diag, GOLD_HI, 7)
    a.ellipse((CX - 18, CY - 18, CX + 18, CY + 18), fill=GOLD_HI)
    # Las 7 estrellas menores de la carta La Estrella
    rnd = random.Random(77)
    for i, deg in enumerate(range(-90, 270, 51)):
        x, y = P(CX, CY, 352, deg + rnd.uniform(-8, 8))
        mini_star(a, x, y, 26 if i % 2 else 19, GOLD_DEEP if i % 2 else GOLD_HI, 5)
    # Agua serena abajo
    for yy, amp in ((796, 10), (838, 7)):
        a.line(wave_pts(300, 724, yy, amp, 3), fill=GOLD_DEEP, width=6, joint="curve")
    return art


def draw_tower(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Cuerpo de la torre con almenas
    body = [(442, 490), (442, 800), (582, 800), (582, 490)]
    a.polygon(body, fill=GOLD_DEEP + (60,))
    a.line(body + [body[0]], fill=GOLD, width=9, joint="curve")
    for x in (442, 492, 542, 582):
        a.line([(x, 490), (x, 452)], fill=GOLD, width=9)
    a.line([(442, 452), (582, 452)], fill=GOLD, width=9)
    # Ventanas arqueadas con llamas y puerta
    for wx in (484, 544):
        a.arc((wx - 16, 528, wx + 16, 560), 180, 360, fill=GOLD, width=6)
        a.line([(wx - 16, 544), (wx - 16, 588), (wx + 16, 588), (wx + 16, 544)], fill=GOLD, width=6, joint="curve")
        a.polygon([(wx - 8, 588), (wx, 560), (wx + 8, 588)], fill=GOLD_DEEP)
    a.arc((484, 716, 540, 756), 180, 360, fill=GOLD_DEEP, width=6)
    a.line([(484, 736), (484, 800), (540, 800), (540, 736)], fill=GOLD_DEEP, width=6, joint="curve")
    # Corona despedida por el impacto
    crown = [(468, 404), (468, 372), (490, 396), (512, 362), (534, 396), (556, 372), (556, 404)]
    a.polygon(crown, fill=GOLD_DEEP + (60,))
    a.line(crown + [crown[0]], fill=GOLD_HI, width=7, joint="curve")
    # Rayo que la golpea
    bolt = [(690, 196), (596, 330), (644, 336), (548, 470)]
    a.line(bolt, fill=GOLD_HI, width=16, joint="curve")
    a.line(bolt, fill=IVORY, width=5, joint="curve")
    for deg in range(0, 360, 45):
        x, y = P(548, 470, 46, deg)
        a.line([(548, 470), (x, y)], fill=GOLD_HI, width=5)
    for (x, y) in ((420, 410), (620, 430), (380, 520)):
        a.ellipse((x - 5, y - 5, x + 5, y + 5), fill=GOLD)
    return art


def draw_death(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Guadaña: mango + hoja curva
    a.line([(648, 226), (520, 812)], fill=GOLD, width=16, joint="curve")
    a.ellipse((640, 214, 664, 238), fill=GOLD_HI)
    blade_o = [P2((648, 260), 240, math.radians(x)) for x in range(150, 261, 5)]
    blade_i = [P2((648, 260), 150, math.radians(x)) for x in range(260, 149, -5)]
    a.polygon(blade_o + blade_i, fill=GOLD_DEEP + (90,))
    a.line(blade_o, fill=GOLD_HI, width=9, joint="curve")
    a.line(blade_i, fill=GOLD, width=6, joint="curve")
    # Rosa blanca del renacimiento
    cx, cy = 330, 470
    a.line([(cx, cy + 34), (cx + 14, cy + 120), (cx + 40, cy + 230)], fill=GOLD_DEEP, width=8, joint="curve")
    for pdeg in (200, 250, 300, 350, 30):
        lx, ly = P(cx, cy, 34, pdeg)
        leaf(a, (lx + 20, ly), 38, 17, pdeg + 20, GOLD_DEEP, 5)
    a.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), outline=IVORY, width=6)
    for i in range(5):
        x, y = P(cx, cy, 24, -90 + i * 72)
        a.arc((x - 22, y - 22, x + 22, y + 22), -90 + i * 72 - 60, -90 + i * 72 + 60, fill=IVORY, width=4)
    mini_star(a, 700, 640, 22, IVORY, 4)
    mini_star(a, 250, 300, 17, GOLD_DEEP, 4)
    return art


def draw_wheel(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Triple anillo y hub de la Rueda de la Fortuna
    a.ellipse((CX - 240, CY - 240, CX + 240, CY + 240), fill=GOLD_DEEP + (45,), outline=GOLD, width=10)
    a.ellipse((CX - 195, CY - 195, CX + 195, CY + 195), outline=GOLD_DEEP, width=6)
    a.ellipse((CX - 55, CY - 55, CX + 55, CY + 55), fill=GOLD_DEEP + (60,), outline=GOLD_HI, width=8)
    # 8 radios
    for i in range(8):
        a.line([P(CX, CY, 55, i * 45), P(CX, CY, 195, i * 45)], fill=GOLD, width=7)
    # Letras T·A·R·O en los puntos cardinales internos
    font = load_font(58)
    for txt, deg in (("T", -90), ("A", 0), ("R", 90), ("O", 180)):
        x, y = P(CX, CY, 150, deg)
        text_center(a, (x, y), txt, font, GOLD_HI)
    # Glifos menores en las diagonales del aro
    for i in range(4):
        x, y = P(CX, CY, 218, 45 + i * 90)
        a.ellipse((x - 16, y - 16, x + 16, y + 16), outline=GOLD_DEEP, width=6)
    # Chispas exteriores
    for deg in range(22, 360, 45):
        x, y = P(CX, CY, 282, deg)
        mini_star(a, x, y, 16, GOLD_DEEP, 4)
    return art


def draw_cups(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Cáliz: copa, tallo y base
    a.arc((372, 290, 652, 570), 0, 180, fill=GOLD, width=10)
    a.ellipse((372, 412, 652, 448), outline=GOLD, width=6)
    a.line(wave_pts(400, 624, 470, 9, 3), fill=GOLD_DEEP, width=6, joint="curve")
    a.line([(512, 452), (512, 640)], fill=GOLD, width=14)
    a.ellipse((412, 640, 612, 692), outline=GOLD, width=8)
    a.ellipse((424, 650, 600, 682), outline=GOLD_DEEP, width=4)
    # Hostia y las 5 gotas que brotan de la copa (As de Copas)
    a.ellipse((CX - 22, 278, CX + 22, 322), outline=IVORY, width=6)
    a.line([(CX, 282), (CX, 318)], fill=IVORY, width=4)
    a.line([(CX - 18, 300), (CX + 18, 300)], fill=IVORY, width=4)
    for (x, y, r) in ((402, 250, 13), (462, 216, 16), (512, 200, 18), (562, 216, 16), (622, 250, 13)):
        teardrop(a, x, y, r, GOLD_HI, 6, up=True)
    mini_star(a, 330, 560, 18, GOLD_DEEP, 4)
    mini_star(a, 690, 520, 22, GOLD_DEEP, 5)
    return art


def draw_swords(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Espada vertical atravesando la corona (As de Espadas)
    a.ellipse((486, 184, 538, 236), outline=GOLD_HI, width=8)
    a.line([(512, 236), (512, 330)], fill=GOLD, width=20)
    a.line([(422, 350), (602, 350)], fill=GOLD, width=18)
    a.ellipse((410, 338, 434, 362), fill=GOLD_HI)
    a.ellipse((590, 338, 614, 362), fill=GOLD_HI)
    # Hoja con lomo central
    a.polygon([(494, 359), (530, 359), (518, 822), (512, 852), (506, 822)], fill=GOLD_DEEP + (70,))
    a.line([(494, 359), (506, 822), (512, 852), (518, 822), (530, 359)], fill=GOLD, width=8, joint="curve")
    a.line([(512, 376), (512, 800)], fill=GOLD_HI, width=4)
    # Ramitas de olivo en la guarda
    leaf(a, (398, 322), 52, 18, -30, GOLD_DEEP, 5)
    leaf(a, (626, 322), 52, 18, 30, GOLD_DEEP, 5)
    # Corona en la punta
    crown = [(452, 902), (452, 870), (478, 892), (512, 862), (546, 892), (572, 870), (572, 902)]
    a.polygon(crown, fill=GOLD_DEEP + (60,))
    a.line(crown + [crown[0]], fill=GOLD_HI, width=7, joint="curve")
    for x, ytop in ((452, 870), (512, 862), (572, 870)):
        a.ellipse((x - 7, ytop - 16, x + 7, ytop - 2), fill=GOLD_HI)
    mini_star(a, 320, 220, 20, GOLD_DEEP, 4)
    mini_star(a, 700, 250, 24, GOLD_HI, 5)
    return art


def draw_wands(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Bastón diagonal con brotes (As de Bastos)
    a.line([(352, 828), (600, 262)], fill=GOLD, width=46, joint="curve")
    a.ellipse((329, 805, 375, 851), fill=GOLD_DEEP)
    a.ellipse((577, 239, 623, 285), fill=GOLD_HI)
    a.line([(364, 806), (596, 280)], fill=GOLD_HI, width=8, joint="curve")
    # Brotes de gota a los lados de la punta
    teardrop(a, 520, 250, 13, GOLD_DEEP, 5, up=True)
    teardrop(a, 665, 300, 13, GOLD_DEEP, 5, up=True)
    # Chispas de voluntad
    for (x, y, r) in ((700, 190, 24), (510, 150, 17), (740, 300, 15)):
        mini_star(a, x, y, r, GOLD_HI, 5)
    # Terrón con brote en la base
    a.arc((300, 790, 470, 900), 180, 360, fill=GOLD_DEEP, width=6)
    a.ellipse((368, 872, 384, 888), fill=GOLD_DEEP)
    a.ellipse((400, 884, 414, 898), fill=GOLD_DEEP)
    mini_star(a, 280, 320, 18, GOLD_DEEP, 4)
    return art


def draw_pentacles(d):
    art = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    a = ImageDraw.Draw(art)
    # Moneda con pentagrama (As de Oros)
    a.ellipse((CX - 225, CY - 225, CX + 225, CY + 225), fill=GOLD_DEEP + (55,), outline=GOLD, width=10)
    a.ellipse((CX - 186, CY - 186, CX + 186, CY + 186), outline=GOLD_DEEP, width=5)
    verts = [P2((CX, CY), 165, math.radians(-90 + i * 72)) for i in range(5)]
    for i in range(5):
        a.line([verts[i], verts[(i + 2) % 5]], fill=GOLD_HI, width=8)
    # Brotes de laurel abajo, flanqueando la moneda
    leaf(a, (CX - 250, CY + 262), 46, 20, -135, GOLD_DEEP, 5)
    leaf(a, (CX + 250, CY + 262), 46, 20, 135, GOLD_DEEP, 5)
    mini_star(a, CX, 120, 20, GOLD_HI, 5)
    mini_star(a, 200, 640, 16, GOLD_DEEP, 4)
    mini_star(a, 810, 600, 18, GOLD_DEEP, 4)
    return art


SYMBOLS = [
    ("sun", draw_sun),
    ("moon", draw_moon),
    ("star", draw_star),
    ("tower", draw_tower),
    ("death", draw_death),
    ("wheel", draw_wheel),
    ("cups", draw_cups),
    ("swords", draw_swords),
    ("wands", draw_wands),
    ("pentacles", draw_pentacles),
]


# ---------------------------------------------------------------- Generación


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    for idx, (name, draw) in enumerate(SYMBOLS):
        img = canvas()
        decorate(img, seed=1234 + idx * 77)
        art = draw(img)
        compose(img, art)
        path = os.path.join(OUTDIR, f"symbol_{name}.png")
        img.convert("RGB").resize((OUT, OUT), Image.LANCZOS).save(path, optimize=True)
        print(f"✓ symbol_{name}.png")


if __name__ == "__main__":
    main()
