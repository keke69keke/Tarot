#!/usr/bin/env python3
"""
enrich_cards_v4.py
==================
Enriquece la información de las cartas del Tarot leyendo el libro
"Guía Definitiva del Tarot" (Fiebig & Bürger) en:
  `TarotContent/Resources/book_chapters.json`

Mapas:
  - Arcanos Mayores: se identifica el numeral romano del capítulo y se mapea
    al id estándar de Rider-Waite (I=1 Mago... XXI=21 Mundo). La carta 0
    (El Loco) se asigna por orden secuencial al primer capítulo de arcanos.
  - Arcanos Menores: se localiza el capítulo del palo correspondiente que
    mejor coincida con el número/figura de la carta.

Genera `cards.json` actualizado (con copia de seguridad automática).
"""

import json
import re
import os
import shutil

BASE = os.path.dirname(os.path.abspath(__file__))
BOOKS_PATH = os.path.join(BASE, "TarotContent", "Resources", "book_chapters.json")
CARDS_PATH = os.path.join(BASE, "TarotContent", "Resources", "cards.json")


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# ── Identificación de Arcanos Mayores por numeral romano ────────────────────
# El libro usa numeración estándar: I=Mago(1), II=Sacerdotisa(2), ... XXI=Mundo(21).
# La carta 0 (El Loco) no tiene numeral; se asigna por orden al primer capítulo.
ROMAN_TO_ID = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6,
    "VII": 7, "VIII": 8, "IX": 9, "X": 10, "XI": 11,
    "XII": 12, "XIII": 13, "XIV": 14, "XV": 15, "XVI": 16,
    "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
}

# Trozos de contenido distintivos por carta para los capítulos sin numeral.
MAJOR_NAME_HINTS = {
    0: ["el loco", "locura"],
    1: ["el mago", "mago"],
    2: ["sacerdotisa"],
    3: ["emperatriz"],
    4: ["emperador"],
    5: ["sumo sacerdote", "hierofante", "jerofante"],
    6: ["amantes"],
    7: ["el carro", "auriga"],
    8: ["la fuerza", "doma"],
    9: ["ermitaño", "ermitano", "lámpara"],
    10: ["rueda de la fortuna", "rueda"],
    11: ["justicia"],
    12: ["colgado"],
    13: ["la muerte", "muerte"],
    14: ["templanza"],
    15: ["diablo"],
    16: ["torre"],
    17: ["estrella"],
    18: ["luna"],
    19: ["sol"],
    20: ["juicio"],
    21: ["mundo"],
}


def identify_major_card_id(chapter_content):
    """Devuelve el id de la carta (0-21) que describe el capítulo, o None."""
    content = chapter_content
    # 1) Buscar numeral romano al inicio: "VII-EL CARRO", "XVII-LA ESTRELLA"...
    m = re.search(r"\b(XXI|XX|XIX|XVIII|XVII|XVI|XV|XIV|XIII|XII|XI|X|IX|VIII|VII|VI|V|IV|III|II|I)\s*[-–—]\s*", content)
    if m:
        numeral = m.group(1).upper()
        if numeral in ROMAN_TO_ID:
            return ROMAN_TO_ID[numeral]
    # 2) Fallback: buscar nombre distintivo.
    lower = content.lower()
    for cid, hints in MAJOR_NAME_HINTS.items():
        for h in hints:
            if h in lower:
                return cid
    return None


def rank_keywords(rank):
    """Keywords para el emparejamiento de Arcanos Menores."""
    rank = rank.lower()
    table = {
        "as": ["as", "ace", "1"],
        "dos": ["dos", "two", "2"],
        "tres": ["tres", "three", "3"],
        "cuatro": ["cuatro", "four", "4"],
        "cinco": ["cinco", "five", "5"],
        "seis": ["seis", "six", "6"],
        "siete": ["siete", "seven", "7"],
        "ocho": ["ocho", "eight", "8"],
        "nueve": ["nueve", "nine", "9"],
        "diez": ["diez", "ten", "10"],
        "sota": ["sota", "paje", "page", "jack", "valet"],
        "paje": ["sota", "paje", "page", "jack", "valet"],
        "caballero": ["caballero", "knight", "cavallero"],
        "reina": ["reina", "queen"],
        "rey": ["rey", "king"],
    }
    return table.get(rank, [rank])


def find_minor_chapter_index(card, chapters):
    """Localiza el índice del capítulo que describe una carta menor."""
    suit_key = card.get("suit", "").lower()
    suit_ranges = {
        "wands": list(range(42, 58)),
        "cups": list(range(58, 74)),
        "swords": list(range(74, 92)),
        "pentacles": list(range(92, 106)),
    }
    candidates = suit_ranges.get(suit_key, [])

    rank = card["name"].split(" de ")[0].lower()
    keywords = rank_keywords(rank)

    best_idx = None
    best_score = 0
    for idx in candidates:
        if idx >= len(chapters):
            continue
        content = chapters[idx].get("content", "").lower()
        title = chapters[idx].get("title", "").lower()
        haystack = title + " " + content
        score = 0
        for kw in keywords:
            if kw in haystack:
                score += 1
        if score > best_score:
            best_score = score
            best_idx = idx
    return best_idx


def main():
    books = load_json(BOOKS_PATH)
    catalog = load_json(CARDS_PATH)
    cards = catalog["cards"]

    # ── Mapear capítulos de Arcanos Mayores ──────────────────────────────
    major_chapter_ids = list(range(22, 42))  # índices 22..41
    major_map = {}  # card_id -> chapter dict
    used_ids = set()

    # Primera pasada: asignar por numeral romano.
    for idx in major_chapter_ids:
        if idx >= len(books):
            continue
        cid = identify_major_card_id(books[idx].get("content", ""))
        if cid is not None and cid not in used_ids:
            major_map[cid] = books[idx]
            used_ids.add(cid)

# Segunda pasada: asignar El Loco (0) al primer capítulo no usado.
    used_chapter_indices = {books.index(b) for b in major_map.values()}
    for idx in major_chapter_ids:
        if idx >= len(books):
            continue
        if idx in used_chapter_indices:
            continue
        if 0 not in used_ids:
            major_map[0] = books[idx]
            used_ids.add(0)
            break

    enriched_count = 0
    for card in cards:
        new_book = None
        if card["arcanaType"] == "major":
            chapter = major_map.get(card["id"])
            if chapter:
                new_book = chapter.get("content", "")
        else:
            idx = find_minor_chapter_index(card, books)
            if idx is not None:
                new_book = books[idx].get("content", "")

        if new_book and len(new_book.strip()) > 100:
            card["bookContent"] = "[Guía Definitiva del Tarot — Fiebig & Bürger]\n\n" + new_book.strip()
            enriched_count += 1

    # Copia de seguridad antes de guardar.
    shutil.copy(CARDS_PATH, CARDS_PATH + ".bak")
    save_json(CARDS_PATH, catalog)
    print(f"Cartas enriquecidas: {enriched_count}/{len(cards)}")


if __name__ == "__main__":
    main()
