#!/usr/bin/env python3
"""Analyze bundled PDFs to identify stub files (only title/subtitle)."""
import glob
import os
import sys

try:
    from pypdf import PdfReader
except ImportError:
    try:
        from PyPDF2 import PdfReader
    except ImportError:
        print("NO_PDF_LIB")
        sys.exit(0)

os.chdir(os.path.join(os.path.dirname(__file__), "..", "TarotContent", "Resources", "Books"))

for f in sorted(glob.glob("*.pdf")):
    try:
        r = PdfReader(f)
        n = len(r.pages)
        total = 0
        nonempty = 0
        for p in r.pages:
            try:
                t = p.extract_text() or ""
            except Exception:
                t = ""
            if len(t.strip()) > 0:
                total += len(t.strip())
                nonempty += 1
        avg = total // nonempty if nonempty else 0
        print(f"PAGES={n:4} TEXTLEN={total:7} NONEMPTY={nonempty:3} AVG={avg:5} | {f}", flush=True)
    except Exception as e:
        print(f"ERR {f}: {e}", flush=True)
