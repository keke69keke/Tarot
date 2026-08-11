import os
import glob

os.chdir('/Users/nicole/Downloads/Tarot/TarotContent/Resources/Books')

try:
    from pypdf import PdfReader
except ImportError:
    try:
        from PyPDF2 import PdfReader
    except ImportError:
        print('NO_PDF_LIB')
        raise SystemExit(0)

files = ['La_Clave_Ilustrada_del_Tarot.pdf',
         'Guia_Tiradas_Avanzadas.pdf',
         'Historia_del_Tarot.pdf',
         'El_Tarot_de_Marsella.pdf']

for f in files:
    try:
        r = PdfReader(f)
        print('===', f, 'pages:', len(r.pages))
        for i, p in enumerate(r.pages[:3]):
            t = p.extract_text() or ''
            print('  page {}: {} chars, preview: {!r}'.format(i, len(t), t[:150]))
    except Exception as e:
        print(f, 'ERR', repr(e))
