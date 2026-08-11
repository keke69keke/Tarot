# Plan de implementación

## 🎨 Tarea 1: Arreglar Hello Kitty
- [x] Crear script `scripts/crop_hello_kitty.py` que recorte las 78 imágenes de 1100x1275 a 869x1275 (proporción 150:220).
- [x] Ejecutar el script.
- [x] Verificar dimensiones resultantes (869x1275).
- [x] **Fix de renderizado en `CardFace`**: forzar `.fill` cuando `activeDeck == .helloKitty` para eliminar las franjas blancas que causaba el `.fit` (el arte ya viene precortado a la proporción de carta). Para otros mazos, solo usar `.fit` si la imagen es claramente más ancha que el marco (+0.03 de tolerancia).

## 🎨 Tarea 2: Mejorar mazos sin imágenes
- [x] Modificar `CardFallbackIllustration` en `TarotUI/Placeholder.swift` para recibir el `textureStyle` del mazo y mostrar fondo con textura + nombre + borde dorado.
- [x] Actualizar las llamadas a `CardFace` para pasar el deck activo.
- [x] **Intensificar todas las texturas procedurales** de `CardTextureOverlayView` para que cada mazo se distinga con claridad:
  - Rider-Waite (agedParchment): +opacidad de líneas y gradiente pergamino.
  - Thoth (sacredGeometry): +opacidad de círculos y hexagramas.
  - Hello Kitty (softPastel): +brillo pastel y destellos tipo sparkle.
  - Marsella (medievalEmbroidery): +rejilla y diagonales bordadas.
  - Osho (watercolor): +manchas de acuarela más visibles.
  - DarkSide (grunge): +rayones y oscuridad.
  - Celestial (starfield): +campo de estrellas más brillante.
  - Botánico (leafVeins): +venas de las hojas más marcadas.

## 📚 Tarea 3: Añadir más libros
- [x] Ejecutar `python3 create_pdf.py` para generar los 24 libros.
- [x] Registrar los 24 libros en `LibraryManager.swift` (preloadedBookTitles y preloadedBookNames).
- [x] Verificar compilación (65 libros totales en `TarotContent/Resources/Books/`).

## 💡 Tarea 4: Sugerencias de engagement (ver resultado final)

## ✅ Verificación
- [x] `swift build` para verificar compilación.
