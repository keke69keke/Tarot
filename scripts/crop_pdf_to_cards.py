#!/usr/bin/env python3
"""
crop_pdf_to_cards.py

Crop a PDF into individual card images using a grid layout per page.

Requirements:
  pip install pymupdf pillow

Usage examples:
  # Basic: split each PDF page into a 3x3 grid and save PNGs
  python3 scripts/crop_pdf_to_cards.py input.pdf out_dir --rows 3 --cols 3

  # Specify margins in pixels (after rendering at given DPI)
  python3 scripts/crop_pdf_to_cards.py input.pdf out_dir --rows 3 --cols 3 --margin-left 10 --margin-top 10 --margin-right 10 --margin-bottom 10

  # Provide page range (1-based) and file name mapping JSON
  python3 scripts/crop_pdf_to_cards.py input.pdf out_dir --rows 3 --cols 3 --pages 1-4 --naming-file names.json

The script saves files as: prefix_000.png by default and increments across pages.
If a naming file (JSON array of filenames) is provided, those names will be used in order.

Notes:
 - The script renders PDF pages at a specified DPI then computes crop boxes in pixels.
 - If the cards on the PDF pages are not perfectly aligned in a regular grid, consider
   using a GUI crop tool instead or supply exact crop boxes externally.
"""

import sys
import os
import argparse
import json
from math import floor

try:
    import fitz  # PyMuPDF
    from PIL import Image
except Exception as e:
    print("Missing dependencies. Install with: pip install pymupdf pillow")
    raise


def parse_pages_arg(pages_arg, doc_page_count):
    # pages_arg like "1-3,5" (1-based). Return list of 0-based page indices.
    if not pages_arg:
        return list(range(doc_page_count))
    pages = set()
    parts = pages_arg.split(',')
    for p in parts:
        p = p.strip()
        if '-' in p:
            a,b = p.split('-',1)
            a = int(a)
            if b == '':
                b = doc_page_count
            else:
                b = int(b)
            for i in range(a, b+1):
                if 1 <= i <= doc_page_count:
                    pages.add(i-1)
        else:
            i = int(p)
            if 1 <= i <= doc_page_count:
                pages.add(i-1)
    return sorted(pages)


def render_page_to_pil(page, dpi=300):
    mat = fitz.Matrix(dpi/72.0, dpi/72.0)
    pix = page.get_pixmap(matrix=mat, alpha=False)
    mode = "RGB"
    img = Image.frombytes(mode, [pix.width, pix.height], pix.samples)
    return img


def crop_grid(img, rows, cols, margin_left, margin_top, margin_right, margin_bottom):
    w, h = img.size
    # compute available area
    left = margin_left
    top = margin_top
    right = w - margin_right
    bottom = h - margin_bottom
    if right <= left or bottom <= top:
        raise ValueError("Margins too large for page dimensions")
    avail_w = right - left
    avail_h = bottom - top
    cell_w = avail_w / cols
    cell_h = avail_h / rows
    boxes = []
    for r in range(rows):
        for c in range(cols):
            x0 = int(round(left + c * cell_w))
            y0 = int(round(top + r * cell_h))
            x1 = int(round(left + (c+1) * cell_w))
            y1 = int(round(top + (r+1) * cell_h))
            boxes.append((x0, y0, x1, y1))
    return boxes


def main():
    p = argparse.ArgumentParser(description="Crop PDF pages into a grid of card images")
    p.add_argument('input_pdf')
    p.add_argument('out_dir')
    p.add_argument('--rows', type=int, required=True, help='number of rows per page')
    p.add_argument('--cols', type=int, required=True, help='number of columns per page')
    p.add_argument('--dpi', type=int, default=300, help='rendering DPI (default 300)')
    p.add_argument('--margin-left', type=int, default=0)
    p.add_argument('--margin-top', type=int, default=0)
    p.add_argument('--margin-right', type=int, default=0)
    p.add_argument('--margin-bottom', type=int, default=0)
    p.add_argument('--prefix', type=str, default='card', help='filename prefix')
    p.add_argument('--format', type=str, default='png', choices=['png','jpeg','jpg'])
    p.add_argument('--pad', type=int, default=3, help='zero padding for numeric suffix')
    p.add_argument('--start-index', type=int, default=0)
    p.add_argument('--naming-file', type=str, help='optional JSON array with output file basenames (no extension)')
    p.add_argument('--pages', type=str, help='page ranges (1-based), e.g. 1-3,5')
    args = p.parse_args()

    if not os.path.exists(args.input_pdf):
        print(f"Input PDF not found: {args.input_pdf}")
        sys.exit(2)
    os.makedirs(args.out_dir, exist_ok=True)

    doc = fitz.open(args.input_pdf)
    page_indices = parse_pages_arg(args.pages, len(doc))

    naming = None
    if args.naming_file:
        with open(args.naming_file, 'r', encoding='utf-8') as f:
            naming = json.load(f)
        if not isinstance(naming, list):
            print("Naming file must be a JSON array of filenames")
            sys.exit(2)

    index = args.start_index
    naming_idx = 0
    for pi in page_indices:
        page = doc[pi]
        img = render_page_to_pil(page, dpi=args.dpi)
        boxes = crop_grid(img, args.rows, args.cols, args.margin_left, args.margin_top, args.margin_right, args.margin_bottom)
        for box in boxes:
            crop = img.crop(box)
            if naming is not None and naming_idx < len(naming):
                out_name = naming[naming_idx]
            else:
                out_name = f"{args.prefix}_{str(index).zfill(args.pad)}"
            out_path = os.path.join(args.out_dir, f"{out_name}.{args.format}")
            crop.save(out_path)
            print(f"Saved {out_path}")
            index += 1
            naming_idx += 1

    print("Done.")

if __name__ == '__main__':
    main()
