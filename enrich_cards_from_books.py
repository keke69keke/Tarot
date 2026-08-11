#!/usr/bin/env python3
"""
Enrich cards.json with bookContent extracted from the 42 bundled PDF books.

For each card, search the book corpus for the card's name and related keywords,
then extract a relevant excerpt to store in `bookContent`.
"""

import json
import re

CARDS_PATH = "TarotContent/Resources/cards.json"
CORPUS_PATH = "/tmp/books_corpus.json"


def load_corpus():
    with open(CORPUS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def extract_excerpt(text, keyword, context_chars=1000):
    """Find the best occurrence of `keyword` in `text` and return a surrounding excerpt."""
    lower_text = text.lower()
    lower_keyword = keyword.lower()

    # Find all occurrences
    indices = []
    start = 0
    while True:
        idx = lower_text.find(lower_keyword, start)
        if idx == -1:
            break
        indices.append(idx)
        start = idx + len(lower_keyword)

    if not indices:
        return None

    # Prefer an occurrence that looks like a section heading (short line before it)
    best_idx = indices[0]
    best_score = -1
    for idx in indices:
        line_start = text.rfind("\n", 0, idx)
        if line_start == -1:
            line_start = 0
        line = text[line_start:idx].strip()
        score = 0
        if len(line) < 60:
            score += 10  # Likely a heading
        if idx > 500:
            score += 1  # Skip front-matter
        if score > best_score:
            best_score = score
            best_idx = idx

    idx = best_idx
    # Expand to a reasonable excerpt
    start = max(0, idx - context_chars // 3)
    para_start = text.rfind("\n\n", 0, start)
    if para_start != -1 and idx - para_start < context_chars:
        start = para_start + 2
    end = min(len(text), idx + context_chars)
    para_end = text.find("\n\n", end)
    if para_end != -1 and para_end - idx < context_chars * 2:
        end = para_end

    excerpt = text[start:end].strip()
    excerpt = re.sub(r"\n{3,}", "\n\n", excerpt)
    return excerpt


def is_tarot_specific(book_name):
    """Return True if the book is specifically about tarot (preferred source)."""
    low = book_name.lower()
    return any(t in low for t in ["tarot", "arcano", "simbolismo", "bohemios", "marsella"])


def main():
    with open(CARDS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    corpus = load_corpus()
    book_texts = corpus

    # Card name variants for searching (Spanish)
    card_name_variants = {
        "El Loco": ["El Loco", "El Loco (0)", "El Loco — 0"],
        "El Mago": ["El Mago", "El Mago (I)", "El Mago — I"],
        "La Suma Sacerdotisa": ["La Suma Sacerdotisa", "La Sacerdotisa", "La Papisa"],
        "La Emperatriz": ["La Emperatriz"],
        "El Emperador": ["El Emperador"],
        "El Sumo Sacerdote": ["El Sumo Sacerdote", "El Hierofante", "El Papa"],
        "Los Amantes": ["Los Amantes", "El Enamorado", "Los Enamorados"],
        "El Carro": ["El Carro", "El Carro de Guerra"],
        "La Fuerza": ["La Fuerza", "La Fuerza (VIII)"],
        "El Ermitaño": ["El Ermitaño", "El Ermitaño (IX)"],
        "La Rueda de la Fortuna": ["La Rueda de la Fortuna", "La Rueda"],
        "La Justicia": ["La Justicia", "La Justicia (XI)"],
        "El Colgado": ["El Colgado", "El Colgado (XII)"],
        "La Muerte": ["La Muerte", "La Muerte (XIII)"],
        "La Templanza": ["La Templanza", "La Templanza (XIV)"],
        "El Diablo": ["El Diablo", "El Diablo (XV)"],
        "La Torre": ["La Torre", "La Torre (XVI)"],
        "La Estrella": ["La Estrella", "La Estrella (XVII)"],
        "La Luna": ["La Luna", "La Luna (XVIII)"],
        "El Sol": ["El Sol", "El Sol (XIX)"],
        "El Juicio": ["El Juicio", "El Juicio (XX)"],
        "El Mundo": ["El Mundo", "El Mundo (XXI)"],
    }

    enriched = 0
    for card in data["cards"]:
        name = card["name"]
        arcana = card.get("arcanaType", "")

        if arcana == "major":
            keywords = card_name_variants.get(name, [name])
        else:
            keywords = [name]
            clean = name
            for article in ["El ", "La ", "Los ", "Las "]:
                if clean.startswith(article):
                    clean = clean[len(article):]
                    break
            if clean != name:
                keywords.append(clean)

        best_excerpt = None
        best_source = None
        best_score_val = -1

        for kw in keywords:
            for book_name, book_text in book_texts.items():
                excerpt = extract_excerpt(book_text, kw)
                if excerpt:
                    score = len(excerpt)
                    if is_tarot_specific(book_name):
                        score += 5000
                    if score > best_score_val:
                        best_score_val = score
                        best_excerpt = excerpt
                        best_source = book_name

        if best_excerpt:
            source_title = re.sub(r"[-_.]", " ", best_source).strip()
            card["bookContent"] = f"[De: {source_title}]\n\n{best_excerpt}"
            enriched += 1
        else:
            card["bookContent"] = None

        print(f"{name}: {'OK' if best_excerpt else 'NO MATCH'} ({len(best_excerpt) if best_excerpt else 0} chars)")

    with open(CARDS_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nEnriched {enriched}/{len(data['cards'])} cards with bookContent.")


if __name__ == "__main__":
    main()
