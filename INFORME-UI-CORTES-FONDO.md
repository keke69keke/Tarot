# Revisión de la UI: barras negras y cortes de fondo — informe

Fecha: 4 de octubre de 2026 · Proyecto: Tarot (`feature/esoteric-expansion`)
Método: compilación real para el simulador (iPhone 18 Pro, iOS 27), capturas de
las 13 pestañas y medición de píxeles. No es una lectura de código: son capturas.

## 1. Respuesta corta

En las **13 pestañas** no hay barras negras ni cortes de fondo:

| Comprobación | Resultado |
|---|---|
| Filas 100 % negras (cualquier franja) | **0 filas** en las 13 pestañas |
| Borde superior (zona de la barra de estado) | violeta `(23,15,46)` en el **100 %** del ancho |
| Borde inferior | sin negro: fondo propio o barra flotante de la app |

La franja negra de 62 pt bajo la barra de estado que el informe del 2 de octubre
detectó y corrigió **sigue corregida**: el violeta llega hasta y=0 en todas.

**Aparte de las pestañas, sí había dos defectos reales, ambos en el modal
«Reemplazar carta»** (al que no se llega navegando, hay que abrirlo): fondo gris
del sistema en vez de violeta, y el campo de búsqueda pintado como una banda
negra. Ambos localizados, corregidos y medidos. Detalle en §5.1.

## 2. Antes de medir el fondo, hubo que arreglar un cierre inesperado

La app **abortaba con SIGABRT al arrancar** con la configuración guardada, así
que la primera captura mostró una pantalla vacía y las medidas no eran posibles.

- Informe de fallo: `~/Library/Logs/DiagnosticReports/Tarot-2026-10-04-044116.ips`
- Causa: `EXC_CRASH / SIGABRT`, hilo 0
- Traza: `RB::precondition_failure` ← `RBDrawingStateBeginLayer` ←
  `GraphicsContext.drawLayer` ← `MoonDiscView.body` (un `Canvas`)

El defecto estaba en `TarotUI/Views/LunarPhasesView.swift`: dentro de la capa ya
abierta con `contexto.drawLayer { capa in … }`, la capa oscura se abría con
`contexto.drawLayer` —el contexto **exterior**— en vez de `capa.drawLayer`. Abrir
una capa anidada desde el padre mientras hay otra abierta corrompe el display
list de RenderBox y aborta. Corregido a `capa.drawLayer`.

Es un fallo de cara al usuario: quien tuviera «Fases lunares» seleccionada no
podía abrir la app. Tras la corrección arranca y se mantiene estable (medido a
1, 2, 3, 5, 10, 15, 25 y 35 s sin volver al inicio y sin informes de fallo nuevos).

## 3. Verificación ejecutada

| Comprobación | Comando | Resultado |
|---|---|---|
| Compilación iOS | `xcodebuild -scheme Tarot -destination 'platform=iOS Simulator,id=…'` | **BUILD SUCCEEDED** |
| Suite completa | `swift test` | **196 tests, 0 fallos** |
| Capturas | `xcrun simctl io … screenshot` | 13 pestañas, una por pestaña |
| Análisis de píxeles | script propio sobre las capturas | 0 filas negras; borde superior violeta 100 % |
| Modal (antes/después) | capturas del modal abierto | gris `(28,28,30)` → violeta `(15,10,33)`; 2 bandas negras → 0 |
| Identidad de cada captura | OCR de las miniaturas | confirma que cada una es la pestaña pedida |

Las 13: `reading`, `ask`, `horoscope`, `library`, `daily`, `learn`, `journal`,
`settings`, `chat`, `biorhythm`, `natal`, `soulLink`, `lunar`. En la hoja de
contacto se ven todas juntas: fondo continuo, sin costuras ni bandas.

## 4. Dos cosas que conviene no confundir con cortes

**(a) El destello amarillo del arranque no es de Tarot.** Durante el lanzamiento
en frío aparece un amarillo `(255,229,0)`. Rastericé el icono de la app (su color
medio es violeta `(14,9,27)`), busqué `yellow` en todo el código y en el
`Assets.car` compilado: **no sale de Tarot**. Es la pantalla de la app que el
simulador tenía al frente, **Mercado Pago** (`com.gvstii.mercadopagoios`), cuyo
amarillo de marca es `#FFE600 = (255,230,0)`: coincidencia exacta. El
`UILaunchScreen` de Tarot está vacío y el sistema usa el fondo oscuro. Conclusión:
en frío el sistema muestra ese amarillo un par de segundos y luego entra Tarot;
no es un defecto del proyecto. Si molesta, se arregla reiniciando el simulador.

**(b) Los «saltos» de píxel en los bordes son contenido, no cortes.** En 8 de las
13 pestañas el escaneo detecta saltos fuertes de color en la columna del borde.
Los revisé recortando la zona: son texto blanco («Tirada»), tarjetas, gráficas y
el borde de paneles de vidrio. Ninguno es una discontinuidad del fondo.

## 5. Modales (`sheet`) — el punto pendiente, ya verificado

El informe anterior dejó anotado que los 14 `NavigationStack` sin fondo eran
mayoría `sheet`s. Lo comprobé uno a uno, y esta vez **abrí el modal de verdad**
para medirlo: al no haber GUI del simulador, añadí un argumento de lanzamiento
temporal (`-qa-picker`) en el proyecto real, compilé, capturé, y **retiré el
gancho** dejando el archivo idéntico al respaldo (verificado por `diff` y md5).

### 5.1 `replacementPickerSheet`: dos defectos reales, corregidos

Aparecía gris del sistema `(28,28,30)`, no violeta: **no aplicaba ningún fondo**.
Y el campo «Buscar carta» se pintaba como una **franja negra pura**, con filas
100 % negras de 41 y 31 px de alto.

| | antes | después |
|---|---|---|
| Color dominante del modal | gris `(28,28,30)` | violeta `(15,10,33)` |
| Franjas 100 % negras | 2 (41 px y 31 px) | **0** |

**Causa del fondo:** el modal no declaraba fondo y la vista que lo presenta no se
lo presta. Corregido con `.tarotSheetBackground()`.

**Causa del campo negro:** `.textFieldStyle(.roundedBorder)` es el estilo por
defecto de iOS y se dibuja como una banda opaca; sobre el fondo nocturno se ve
como un agujero. Sustituido por dibujo propio translúcido (radio 10, relleno
`white 0.06`, borde `tarotGold 0.22`).

Ambas correcciones en `TarotUI/Views/ReadingView.swift` (líneas ~222 y ~263).

### 5.2 Resto de modales

| Modal | Fondo |
|---|---|
| `CardAIDeepDiveSheet` | `tarotNightBackground()` ✅ |
| `AddSoulSheet` | `Color.tarotBackground` ✅ |
| `DreamEntrySheet`, `DreamDetailView` | `Form`/`ScrollView` con `preferredColorScheme(.dark)` ✅ |
| `SectionsTutorialView` | `Color.tarotBackground` + degradado ✅ |
| `TarotWebBrowserView` | medido abriéndolo: **sin banda negra**, la píldora del campo se integra ✅ |
| `drawnCardDetailSheet` (en `ReadingView`) | `Color.tarotBackground` ✅ |
| `replacementPickerSheet` | **corregido en este run** ✅ |

`TarotWebBrowserView` usa el mismo `.roundedBorder` obsoleto (línea 40), pero
**medido en pantalla no produce banda negra** en modo oscuro: se ve como una
píldora gris integrada. No lo toqué: sin defecto medido, no hay nada que
arreglar.

## 6. Cómo se verificó sin poder pulsar botones

El simulador de este equipo no tiene GUI utilizable, así que no se puede tocar
un botón para que aparezca un modal. El método fue:

1. Copiarlo todo a un directorio temporal limpio (sin los `._*` del volumen).
2. Añadir un argumento de lanzamiento temporal que abre el modal al arrancar.
3. Compilar, lanzar con `xcrun simctl launch … -qa-picker`, capturar y medir.
4. Repetir el paso 3 **con la corrección aplicada** y comparar los píxeles.
5. Aplicar la corrección al proyecto real, recompilar y volver a medir **sobre
   el real**, no sobre la copia.
6. Retirar el gancho y comprobar con `diff` y md5 que el archivo queda idéntico
   al respaldo (sólo la corrección).

Verificado al final: **no queda ningún gancho QA en el código**
(`rg qa-picker|qa-browser` → ninguno).

## 7. Avisos

- **No hice commit** de las correcciones: `LunarPhasesView.swift` (línea 299),
  `ReadingView.swift` (líneas 222 y 263). Dime si quieres que las confirme.
- **Restaqué el estado del simulador** que cambié para recorrer las pestañas
  (dejé el original: `activeTabs = [lunar, reading, horoscope, learn, settings]`).
- **No toqué el pulido visual a medias** (`SecretVaultView` y `SymbolAtlasView`
  siguen fuera del patrón de fondo; `SymbolAtlasView` es subvista de `learn`).
- **`swift build`/`xcodebuild` dentro del volumen falla por `codesign`**, no por
  código: el volumen es exFAT y macOS deposita allí 36.090 archivos `._*`. Las
  compilaciones de este informe se hicieron con `-derivedDataPath` fuera del
  volumen. Mover el proyecto a APFS lo resuelve de raíz.
- Capturas y hoja de contacto en `.zwork/ui-check/`; se pueden borrar sin riesgo.
  Los archivos con prefijo `qa_` son la evidencia del modal antes/después.
