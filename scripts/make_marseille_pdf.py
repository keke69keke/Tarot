#!/usr/bin/env python3
"""Genera el PDF 'El Tarot de Marsella' con portada + 22 arcanos + 4 palos + cierre."""
import os, glob
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
W, HH = A4
OUT = os.path.join(HERE, "..", "TarotContent", "Resources", "Books", "El_Tarot_de_Marsella.pdf")

c = canvas.Canvas(OUT, pagesize=A4)

def card_frame():
    c.setFillColorRGB(0.95, 0.93, 0.87)   # crema marsella
    c.rect(0, 0, W, HH, fill=1)
    c.setStrokeColorRGB(0.23, 0.15, 0.06)
    c.setLineWidth(3)
    c.rect(20, 20, W-40, HH-40)

def put_img(name_fragment, target_h=290, y=HH/2-100):
    pattern = os.path.join(HERE, "..", "TarotContent", "Resources", f"marseille_{name_fragment}*.png")
    imgs = glob.glob(pattern)
    if imgs:
        im = Image.open(imgs[0])
        iw, ih = im.size
        scale = target_h / ih
        iw2 = iw * scale
        c.drawInlineImage(im, (W-iw2)/2, y, width=iw2, height=target_h)

# Portada
card_frame()
c.setFillColorRGB(0.12, 0.08, 0.03)
c.setFont("Helvetica-Bold", 28)
c.drawCentredString(W/2, HH-150, "El Tarot de Marsella")
c.setFont("Helvetica", 16)
c.drawCentredString(W/2, HH-190, "Curso de Estudio del Mazo Clásico")
c.setFont("Helvetica-Oblique", 13)
c.drawCentredString(W/2, HH-230, "Arte xilográfico — Siglo XVII")
put_img("card_00", 220, HH-520)
c.showPage()

major = [
    "El Loco","El Mago","La Sacerdotisa","La Emperatriz","El Emperador",
    "El Papa","Los Enamorados","El Carro","La Fuerza","El Ermitaño",
    "La Rueda de la Fortuna","La Justicia","El Colgado","La Muerte",
    "La Templanza","El Diablo","La Torre","La Estrella","La Luna",
    "El Sol","El Juicio","El Mundo",
]

for i in range(22):
    card_frame()
    put_img(f"card_{i:02d}")
    c.setFillColorRGB(0.12, 0.08, 0.03)
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(W/2, HH-80, f"Arcano {i}: {major[i]}")
    tx = c.beginText(W/2-240, HH-430)
    tx.setFont("Helvetica", 10)
    tx.textLine("Simbolismo escuela Marsella:")
    tx.textLine("")
    tx.textLine(f"• Número {i} — observa la composición geométrica.")
    tx.textLine("• Color dominante: rojo y azul sobre fondo crema.")
    tx.textLine("• La figura central transmite la energía del arcano.")
    tx.textLine("• Estudia también boca abajo (inversión) y su contrario.")
    c.drawText(tx)
    c.showPage()

# Menores: un spread por palo con miniaturas
for suit in ("cups","wands","swords","pentacles"):
    card_frame()
    c.setFillColorRGB(0.12,0.08,0.03)
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(W/2, HH/2+100, f"Palo — {suit.title()}")
    c.setFont("Helvetica", 12)
    c.drawCentredString(W/2, HH/2+65, "As → 10 + 4 figuras cortes")
    # miniaturas de 4 cartas
    base = 112
    for k in range(4):
        put_img(f"card_{base+k}*", 70, HH/2 - 30 - k*90)
    c.setFont("Helvetica", 10)
    c.drawCentredString(W/2, HH/2-300, "Cada palo se mapea a un elemento y una esfera de la vida.")
    c.drawCentredString(W/2, HH/2-320, "Observa cómo las formas se repiten y se combinan.")
    c.showPage()

# Cierre
card_frame()
c.setFillColorRGB(0.12,0.08,0.03)
c.setFont("Helvetica-Oblique", 15)
c.drawCentredString(W/2, HH/2+60, "Gracias por estudiar el Tarot de Marsella.")
c.setFont("Helvetica", 12)
c.drawCentredString(W/2, HH/2, "Las cartas son espejos del alma.")
c.drawCentredString(W/2, HH/2-20, "Confía en tu intuición y la sabiduría antigua.")
c.showPage()

c.save()
print(f"PDF: {OUT}, {os.path.getsize(OUT)//1024} KB")
