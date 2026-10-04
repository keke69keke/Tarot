# Cierre del trabajo pendiente — informe

Fecha: 4 de octubre de 2026 · Proyecto: Tarot · Rama: `feature/esoteric-expansion`

Continúa el `INFORME-FONDO-Y-MENUS.md` del 2 de octubre. Aquel run dejó dos
tareas abiertas: los fallos de test y el port Android. Este run las cierra.

## 1. Punto de partida, medido

El último commit de la rama era del **10 de septiembre**. Por delante había
96 archivos modificados, 589 nuevos y 365 borrados sin confirmar, sin ninguna
entrada de `git stash`.

Antes de tocar nada ejecuté la suite en dos árboles distintos para separar los
fallos preexistentes de los introducidos:

| Árbol | Errores de compilación | `swift test` |
|---|---|---|
| `HEAD` limpio (`eb14703`) | 0 | **0 fallos** |
| Working copy sin confirmar | 0 | **14 fallos** |

De ahí sale el dato que importa: **el código no tenía errores de compilación,
pero el working copy había roto 14 pruebas que en `HEAD` pasaban.** No eran
preexistentes; los había introducido el trabajo sin confirmar.

## 2. Los 14 fallos: dos causas, no catorce

### 2.1 Doce fallos — regresión en `TarotContent/Placeholder.swift`

Síntoma: `cards.json not found in bundle` (8 fallos) y
`Falta el audio ambiental tarot_*` (5 valores dentro de un mismo caso).

Ese archivo se había reescrito para no usar `Bundle.module`, con buen criterio:
el accesor que genera SwiftPM termina en un `Swift.fatalError` que no se puede
capturar con `try?`. La búsqueda nueva prueba cuatro directorios candidatos
derivados de `Bundle.main` y termina en `Bundle.main`.

**El problema:** al correr `swift test`, `Bundle.main` **no** es el bundle de
pruebas, es el binario `xctest` de Xcode. Lo instrumenté y lo confirmé:

```
BUNDLE_MAIN tail=usr/bin isXCTest=false
PROBE tail=Developer/usr/bin name=TarotApp_TarotContent.bundle loaded=false exists=false
PROBE tail=Contents/Developer/usr name=TarotApp_TarotContent.bundle loaded=false exists=false
PROBE tail=Library/Xcode/Agents name=TarotApp_TarotContent.bundle loaded=false exists=false
```

Los cuatro candidatos caen fuera del árbol de compilación y no existen. El
bundle real estaba a un nivel de distancia, como hermano del `.xctest`.

**Corrección:** añadir un ancla de módulo (`TarotContentBundleAnchor`) y un
quinto bloque de candidatos alrededor del bundle que carga el propio código
—`Bundle(for:)`—, que es exactamente lo que resolvía `Bundle.module`. Se
mantiene la degradación a `Bundle.main` como último recurso, así que el
comportamiento en el `.app` no cambia.

### 2.2 Dos fallos — defecto real en el motor lunar

`TarotCore/Models/LunarCycle.swift` es código **nuevo, nunca confirmado**, así
que no aparece en el diff de `HEAD`: nació ya fallando.

Síntoma: `testLosCuartosCabenDondeToca` y `testLunaLlenaAMediaLunacion`.

En `kind(forAge:)` el índice se calculaba truncando hacia abajo:

```swift
let indice = Int((age / octavo).rounded(.down)) % 8
```

Los hitos del ciclo (luna llena, cuartos) caen justo en el borde de un octavo,
y el error de coma flotante los dejaba por debajo. Medido:

```
cuarto:  age=7.382647213249993  ratio=1.999999999999998  floor=1  round=2
mitad:   age=14.765294426499986 ratio=3.999999999999996  floor=3  round=4
3/4:     age=22.147941639750023 ratio=6.000000000000006  floor=6  round=6
```

Con `floor`, la luna llena se reportaba como gibosa creciente. Es un fallo de
cara al usuario: el ritual que muestra la app era el de la fase anterior.

**Corrección:** redondear al octavo más cercano en vez de truncar.

```swift
let indice = Int((age / octavo).rounded()) % 8
```

Los dos hitos caen ahora donde la prueba exige, y el resto de casos no cambia
porque `rounded()` y `rounded(.down)` solo difieren a partir de medio octavo.

Vale la pena notar que **las pruebas lunares estaban bien escritas**: describían
el comportamiento correcto y fue el código el que se equivocó. No toqué ningún
test para que pasara.

## 3. Verificación ejecutada

| Comprobación | Comando | Resultado |
|---|---|---|
| Suite completa | `swift test` | **196 tests, 0 fallos** — `Test Suite 'All tests' passed` |
| Compilación | `swift build` | 0 errores de compilación |
| Selección de la corrección del bundle | revertir solo `Placeholder.swift` | los 12 fallos vuelven → la corrección es la causa |
| Selección de la corrección lunar | revertir solo `LunarCycle.swift` | los 2 fallos vuelven → la corrección es la causa |
| Baseline | `swift test` en `HEAD` limpio | 0 fallos → confirma que los 14 los introdujo el working copy |

Las pruebas se corrieron con `--scratch-path` fuera del volumen (ver §5).

## 4. Port Android

Confirmaste que la eliminación es intencional. Los 117 archivos seguían en el
índice de git pero borrados del disco, así que los confirmé en un commit
**aparte y aislado**, sin arrastrar nada más:

```
0012cad chore(android): retirar el port Android del repo
```

Antes de confirmar verifiqué que lo preparado era solo esa ruta:

```
$ git diff --cached --name-only | sed 's|/.*||' | sort -u
android
```

El código sigue en el historial: `git checkout 0012cad~1 -- android` lo recupera.

## 5. Avisos

- **`swift build` falla en este volumen por firma, no por código.**
  `CodeSign ... code object is not signed at all`. La causa es que el proyecto
  vive en `/Volumes/666`, un volumen **exFAT** (`nodev, nosuid, noowners`), y
  macOS deposita allí 36.090 archivos `._*` (AppleDouble) que `codesign` no
  puede leer. Confirmado que no hay ni un solo error de compilación detrás: al
  compilar y correr las pruebas con `--scratch-path` fuera del volumen, todo
  pasa.
- **El índice de git está dañado por lo mismo.** Cada comando imprime
  `error: non-monotonic index .git/objects/pack/._pack-*.idx`. Es cosmético:
  git sigue operando. Se arregla moviendo el proyecto a un volumen APFS, que
  además resolvería el punto anterior.
- **No toqué el pulido visual interrumpido.** Quedaban `SecretVaultView` y
  `SymbolAtlasView` fuera del patrón de fondo nocturno, y las últimas
  ediciones (`JournalView`, `DestinyGraphView`, 03:34) estaban a medias. No lo
  incluiste en el alcance, así que sigue exactamente como estaba.
- **Los ~600 cambios siguen sin confirmar** (salvo Android). No los commiteé
  porque no me lo pediste; el árbol es tuyo y no quise decidir por ti cómo
  partirlos en commits temáticos.
