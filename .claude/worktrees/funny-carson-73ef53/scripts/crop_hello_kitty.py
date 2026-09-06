#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Recorta las imágenes del mazo Hello Kitty de 1100x1275 (proporción ~0.86,
casi cuadrada) a la proporción exacta de la carta (150:220 ≈ 0.682).

El código de CardFace usa `.fit` cuando la imagen es más ancha que el marco
de la carta, lo que deja franjas en blanco arriba/abajo. Al recortar la
imagen a la proporción 150:220, `.fill` cubrirá todo el marco sin franjas.

Usa PIL si está disponible; si no, usa un recorte binario simple con Python
estándar (PNG 8-bit RGBA) para evitar dependencias.
"""

import os
import sys

# Dimensiones objetivo: ancho 869, alto 1275  (proporción 150:220)
TARGET_W = 869
TARGET_H = 1275

BASE = os.path.dirname(os.path.abspath(__file__))
RESOURCES = os.path.join(BASE, "..", "TarotContent", "Resources")

# Nombres base de las 78 cartas (id 0..77)
CARD_NAMES = [
    "card_00_the_fool","card_01_the_magician","card_02_the_high_priestess",
    "card_03_the_empress","card_04_the_emperor","card_05_the_hierophant",
    "card_06_the_lovers","card_07_the_chariot","card_08_strength",
    "card_09_the_hermit","card_10_wheel_of_fortune","card_11_justice",
    "card_12_the_hanged_man","card_13_death","card_14_temperance",
    "card_15_the_devil","card_16_the_tower","card_17_the_star",
    "card_18_the_moon","card_19_the_sun","card_20_judgement",
    "card_21_the_world","card_22_ace_of_wands","card_23_two_of_wands",
    "card_24_three_of_wands","card_25_four_of_wands","card_26_five_of_wands",
    "card_27_six_of_wands","card_28_seven_of_wands","card_29_eight_of_wands",
    "card_30_nine_of_wands","card_31_ten_of_wands","card_32_page_of_wands",
    "card_33_knight_of_wands","card_34_queen_of_wands","card_35_king_of_wands",
    "card_36_ace_of_cups","card_37_two_of_cups","card_38_three_of_cups",
    "card_39_four_of_cups","card_40_five_of_cups","card_41_six_of_cups",
    "card_42_seven_of_cups","card_43_eight_of_cups","card_44_nine_of_cups",
    "card_45_ten_of_cups","card_46_page_of_cups","card_47_knight_of_cups",
    "card_48_queen_of_cups","card_49_king_of_cups","card_50_ace_of_swords",
    "card_51_two_of_swords","card_52_three_of_swords","card_53_four_of_swords",
    "card_54_five_of_swords","card_55_six_of_swords","card_56_seven_of_swords",
    "card_57_eight_of_swords","card_58_nine_of_swords","card_59_ten_of_swords",
    "card_60_page_of_swords","card_61_knight_of_swords","card_62_queen_of_swords",
    "card_63_king_of_swords","card_64_ace_of_pentacles","card_65_two_of_pentacles",
    "card_66_three_of_pentacles","card_67_four_of_pentacles","card_68_five_of_pentacles",
    "card_69_six_of_pentacles","card_70_seven_of_pentacles","card_71_eight_of_pentacles",
    "card_72_nine_of_pentacles","card_73_ten_of_pentacles","card_74_page_of_pentacles",
    "card_75_knight_of_pentacles","card_76_queen_of_pentacles","card_77_king_of_pentacles",
]


def crop_png_pure(source, dest, target_w, target_h):
    """Recorte PNG estándar (sin PIL) para PNG de 8 bits RGBA/RGB."""
    import struct
    import zlib

    def read_png(path):
        with open(path, "rb") as f:
            data = f.read()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", "No es un PNG válido: " + path
        pos = 8
        idat = b""
        width = height = bitdepth = colortype = None
        while pos < len(data):
            length = struct.unpack(">I", data[pos:pos+4])[0]
            ctype = data[pos+4:pos+8]
            chunk = data[pos+8:pos+8+length]
            if ctype == b"IHDR":
                width, height, bitdepth, colortype = struct.unpack(">IIBB", chunk[:10])
            elif ctype == b"IDAT":
                idat += chunk
            elif ctype == b"IEND":
                break
            pos += 12 + length
        raw = zlib.decompress(idat)
        channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colortype]
        stride = (width * channels * bitdepth // 8)
        rows = []
        for y in range(height):
            row = raw[y * (stride + 1) + 1: (y + 1) * (stride + 1)]
            rows.append(row)
        return width, height, channels, bitdepth, rows

    def write_png(path, width, height, channels, bitdepth, rows):
        def chunk(ctype, cdata):
            c = ctype + cdata
            return struct.pack(">I", len(cdata)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
        ihdr = struct.pack(">IIBBBBB", width, height, bitdepth, 6 if channels == 4 else 2, 0, 0, 0)
        raw = b"".join(b"\x00" + r for r in rows)
        idat = zlib.compress(raw)
        with open(path, "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n")
            f.write(chunk(b"IHDR", ihdr))
            f.write(chunk(b"IDAT", idat))
            f.write(chunk(b"IEND", b""))

    w, h, ch, bd, rows = read_png(source)
    if w == target_w and h == target_h:
        return False  # ya recortada
    # Recorte centrado horizontalmente
    x_start = (w - target_w) // 2
    x_start = max(0, x_start)
    bpp = ch * bd // 8
    new_rows = []
    for row in rows:
        new_rows.append(row[x_start*bpp:(x_start+target_w)*bpp])
    write_png(dest, target_w, target_h, ch, bd, new_rows)
    return True


def main():
    try:
        from PIL import Image, ImageOps
        has_pil = True
    except Exception:
        has_pil = False

    target_dir = RESOURCES
    changed = 0
    for name in CARD_NAMES:
        ext = ".png"
        src = os.path.join(target_dir, "helloKitty_" + name + ext)
        # Crea un archivo temporal recortado y luego lo reemplaza
        tmp = os.path.join(target_dir, "helloKitty_" + name + "_tmp.png")
        if not os.path.exists(src):
            print(f"  ! no existe: {src}")
            continue
        if has_pil:
            img = Image.open(src).convert("RGBA")
            w, h = img.size
            if w == TARGET_W and h == TARGET_H:
                continue
            # Crop centrado
            left = (w - TARGET_W) // 2
            img2 = img.crop((left, 0, left + TARGET_W, TARGET_H))
            img2.save(tmp)
        else:
            if not crop_png_pure(src, tmp, TARGET_W, TARGET_H):
                continue
        os.replace(tmp, src)
        changed += 1
        print(f"  ✓ recortada {name}")

    print(f"\nRecortadas {changed} imágenes de Hello Kitty a {TARGET_W}x{TARGET_H}.")


if __name__ == "__main__":
    main()
