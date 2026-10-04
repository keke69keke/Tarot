# Procedencia del arte de los mazos

Los mazos con artwork dedicado (Hello Kitty y Marsella) se reconstruyeron a partir de dos PDF
aportados por el usuario. Este directorio deja la trazabilidad de ese trabajo, que antes solo
vivia en scripts temporales.

## Contenido

- `deck-manifest.json` — 156 entradas (78 por mazo): id, `imageName`, imagen de origen dentro del
  PDF, archivo de salida, dimensiones y huella SHA-256 de cada PNG, mas la huella de los dos PDF
  de origen. Es el registro auditable del arte que hay hoy en `TarotContent/Resources`.
- `verify-deck-assets.swift` — vuelve a calcular las huellas y falla si algun PNG no coincide con
  el manifiesto.

## Verificar

```bash
swift scripts/deck-assets/verify-deck-assets.swift
```

Sale con codigo 0 si los 156 recursos coinciden. Los dos PDF de origen no se copian al repositorio (material de terceros): el manifiesto guarda su huella SHA-256 para poder comprobar que se parte del archivo correcto. Ademas, la suite de tests incluye
`TarotTests/Smoke/DeckArtworkIntegrityTests.swift`, que valida contenido (no vacio, no bloque
solido), aspecto y unicidad de cada carta sin depender del manifiesto.

## Como se construyo

Hello Kitty (`hello-kitty-tarot-6x13.pdf`, 14 paginas a 612x792 pt):

1. Extraer los JPEG embebidos (filtro DCTDecode, 337x512) con las APIs de PDF de CoreGraphics. En la
   pagina *p* hay seis imagenes con nombres de recurso continuos `Im(6p-5) ... Im(6p)`.
2. Orden: `id = ImN - 1`, verificado por vision en ocho posiciones (Im1 = The Fool, Im22 = The World,
   Im78 = King of Pentacles).
3. Encuadre: el mazo se dibuja con `.fill` sobre un marco 150x220 (0.68182) y las cartas son
   0.65818, asi que se anaden 6 px de relleno por lado replicando el pixel de borde (el borde de
   estas cartas es negro solido) hasta 349x512 = 0.68164. Sin reescalado ni deformacion.

Marsella (`tarot-de-marsella-cartas_compress.pdf`, 7 paginas a 1224x792 pt):

1. Extraer los JPEG embebidos (354x660) y ordenarlos por posicion de lectura (2 filas de 6).
2. El PDF no sigue el orden canonico del mazo, asi que cada carta se identifico una a una con el
   servicio de vision y la asignacion se cerro por biyeccion (78 indices frente a 78 cartas, ocho de
   ellas resueltas por eliminacion) mas comparaciones relativas entre cartas del mismo palo,
   porque los numerales grabados no son legibles de forma fiable por OCR.
3. Se conserva el tamano nativo (354x660, relacion 0.536). Como el marco es 0.68182, `.fill`
   recortaria cerca del 21% de la altura, asi que `CardFace` usa `.fit` para este mazo.

## Peso de los libros (`Books/`)

`probe-pdf-compaction.swift` prueba, para un PDF concreto, si el filtro nativo de macOS
"Reduce File Size" (`QuartzFilterManager`) reduce su tamano de verdad. Imprime el antes y el
despues, comprueba que el numero de paginas no cambia, que el texto sobrevive (busca ocho
palabras de muestra con `PDFDocument.findString`) y omite los PDF con paginas rotadas (el
filtro no conserva bien `/Rotate`). Sale con codigo distinto de cero si empeora.

Medido sobre los 12 PDF mas pesados de la biblioteca (100 de los 129 MB): el filtro **solo
reduce 2 de 12**. Los libros con JPEG2000, JBIG2 o CCITT ya vienen comprimidos de forma
eficiente, y volver a dibujar la pagina los **hincha** (uno pasa de 16.6 MB a 150 MB). Asi que
la recompresion masiva no es viable con las herramientas disponibles; harian falta o bien un
reescritor de objetos PDF (sustituir cada XObject de imagen por un JPEG a ~150 ppp) o bien
enviar menos libros en el bundle y dejar el resto a importacion.

## Generadores antiguos

`scripts/generate_marseille_images.py` y `scripts/generate_symbol_images.py` generaban arte
sintetico (PIL). El primero produjo las cartas placeholder que estaban practicamente en blanco
(56 de 78 identicas), por eso ya no se usa para el arte de las cartas: los `marseille_*.png`
actuales son las cartas reales del PDF. Volver a ejecutarlo sobrescribiria el mazo real.
`scripts/make_marseille_pdf.py` compone el libro `Books/El_Tarot_de_Marsella.pdf` incrustando los
PNG de Resources; requiere PIL y reportlab, que hoy no estan instalados en el entorno.
