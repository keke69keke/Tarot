Instrucciones para crop_pdf_to_cards.py

Objetivo:
  Cortar un PDF de cartas (por ejemplo el PDF de "Hello Kitty Tarot") en imágenes individuales
  con un layout de cuadrícula por página y guardarlas en una carpeta con nombres secuenciales.

Dependencias:
  pip install pymupdf pillow

Ejemplos:
  # Dividir cada página en una cuadrícula 3x3 y guardar PNGs
  python3 scripts/crop_pdf_to_cards.py /ruta/hello_kitty.pdf out/cards --rows 3 --cols 3

  # Ajustar márgenes (en píxeles tras renderizar a 300 DPI)
  python3 scripts/crop_pdf_to_cards.py /ruta/hello_kitty.pdf out/cards --rows 3 --cols 3 --margin-left 20 --margin-top 20 --margin-right 20 --margin-bottom 20

  # Usar un archivo JSON con nombres (ej: ["card_00_the_fool","card_01_the_magician",...]) para nombrar las salidas
  python3 scripts/crop_pdf_to_cards.py /ruta/hello_kitty.pdf out/cards --rows 3 --cols 3 --naming-file names.json

  # Ejemplo específico para Hello Kitty Tarot usando los nombres estándar de cartas
  python3 scripts/crop_pdf_to_cards.py Hello-Kitty-Tarot-6x13.pdf output_cards/hello_kitty --rows 2 --cols 3 --naming-file scripts/hello_kitty_card_names.json --format png

Consejos:
 - Primero probar con --rows y --cols correctos y abrir las imágenes resultantes para verificar los recortes.
 - Si las cartas no están en una cuadrícula regular, el script no hará recortes finos; será necesario recortar manualmente.
 - Para coincidir con el formato de nombre actual del proyecto (por ejemplo: card_00_the_fool.png), crear un JSON con la lista de nombres y usar --naming-file.

Si quieres, puedo:
 - Ejecutar el script aquí si subes el PDF al repositorio o me indicas la ruta local del archivo.
 - Ajustar el script para detectar automáticamente el número de filas/columnas si las cartas tienen marcas visibles (esto requiere visión por computadora adicional).
