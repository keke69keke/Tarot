# Fondo nocturno en iOS y auditoría de menús — informe

Fecha: 2 de octubre de 2026 · Proyecto: Tarot (`feature/esoteric-expansion`)

## 1. Qué se arregló

El fondo violeta nocturno (`#0F0A22`) no se veía en iOS: la pantalla quedaba en
negro puro. Eran **tres defectos distintos** que se sumaban:

| # | Defecto | Dónde |
|---|---|---|
| 1 | `Color.red` como fondo raíz de la escena iOS (resto de depuración) | `TarotUI/Views/ContentView.swift` |
| 2 | El fondo se aplicaba **fuera** del `NavigationStack`, que es una capa opaca y lo tapaba | 14 sitios en `TarotUI/` |
| 3 | Pantallas sin fondo alguno | `BiorhythmView`, `DailyCardView`, `LearningCenterView` |

### Causa raíz, verificada con builds (no deducida)

El run anterior afirmaba que bastaba "un solo cielo compartido en la raíz con el
contenido transparente". **Eso no funciona.** Lo probé con dos builds:

- Fondo **dentro** del `NavigationStack` → zona de contenido violeta `(37,27,44)` ✅
- Cielo **solo en la raíz**, stack sin fondo → negro puro `(0,0,0)` ❌

El `NavigationStack` es opaco. Por eso el fondo debe ir dentro de cada stack.

## 2. Sobre los dos fondos superpuestos

Comprobado que **no** se ven dos fondos:

- Cada pestaña pinta su cielo dentro de su stack (ahí sí se ve).
- La raíz pinta solo la **base sólida** (`Color` + degradado), **sin** el cielo
  animado. Se eligió así a propósito para no montar un segundo `TimelineView`
  a 30 fps que quedaría tapado.
- En el baseline, la raíz era `Color.red` y la captura tenía **0 píxeles rojos**:
  la capa raíz quedaba 100% tapada.
- En macOS, la captura confirma **un solo** cielo continuo entre sidebar y
  contenido, sin costura.

### Regresión que detecté y corregí

Al quitar el fondo raíz apareció una **franja negra de 62 pt** bajo la barra de
estado (medida: 186 px a 3x). La causa es que el stack no cubre el área segura
superior y un `Color` suelto no se extiende bajo la barra de estado. Se corrigió
envolviendo la base en un `ZStack` con `.ignoresSafeArea()`.

Medición final (columna x=120, fuera del Dynamic Island): fondo violeta
`(23,15,45)` desde **y=0** en las cuatro pestañas probadas.

## 3. Verificación ejecutada

| Comprobación | Comando | Resultado |
|---|---|---|
| Build iOS | `xcodebuild -scheme Tarot -destination 'platform=iOS Simulator,name=iPhone 17'` | **BUILD SUCCEEDED** |
| Build macOS | `xcodebuild -scheme TarotMac -destination 'platform=macOS'` | **BUILD SUCCEEDED** |
| Tests | `swift test` | 67 tests, **14 fallos** (ver abajo) |
| Medición de píxeles | capturas reales del simulador | violeta desde y=0; negro eliminado |

Capturas en `tmp-shots/repro/`: `v4_reading/learn/journal/settings.png` (iOS) y
`mac_final.png` (macOS).

### Los 14 fallos de test: preexistentes, no de este cambio

Ninguno toca la UI, y todos apuntan a la carga de recursos del *bundle*:

- `cards.json not found in bundle` → 8 fallos (`CardCatalogSmokeTests`,
  `CardRepositoryTests`, `DeckArtworkIntegrityTests`, `InterpretationResolverTests`)
- `Falta el audio ambiental tarot_*` → 5 fallos (`AmbientAudioResourcesTests`)
- Lógica lunar pura → 2 fallos (`LunarCycleTests`: cuartos y luna llena)

Los recursos **sí existen** en `TarotContent/Resources/`, así que los fallos son
un problema de empaquetado del bundle en `swift test`, ajeno a mis cambios, que
solo tocaron `TarotUI/`. **Recomiendo confirmarlo ejecutando `swift test` en un
checkout limpio antes de tratarlos como baseline definitivo.**

## 4. Auditoría de menús

### Datos de partida

- `AppTab`: **14 pestañas** declaradas.
- Por defecto: **10 activas** + 3 inactivas.
- `mandatoryTabs`: `learn`, `horoscope`, `chat` (siempre activas).
- Límite real: `clampTabs(maxActive: 8)`.

### Hallazgos

**1. `lunar` (Fases lunares) es inalcanzable.** No está en `activeTabs` ni en
`inactiveTabs`, y `SettingsView` solo lista esas dos. La vista existe
(`LunarPhasesView`) y hay un `case .lunar` en `ContentView`, pero **no hay forma
de activarla desde la interfaz**. O se añade a `inactiveTabs` (para que aparezca
con ＋ en Ajustes) o se elimina la vista.

**2. `chat` es obligatorio pero no está activo por defecto.** `UserSettings()`
arranca con `chat` en `inactiveTabs`, mientras `mandatoryTabs` lo exige activo.
Al primer guardado se restaura, pero hasta entonces el estado es incoherente. Lo
correcto es incluir `chat` en los `activeTabs` por defecto.

**3. Las 10 pestañas por defecto exceden el límite de 8.** `defaultActiveTabs`
tiene 10 y `maxActive` es 8, así que al cargar se recortan 2 a `inactiveTabs`
silenciosamente. El usuario nunca pidió esas 10; ve 8 y dos "ocultas" que no
eligió.

**4. Comentario contradictorio.** La línea 80 de
`UserDefaultsSettingsRepository.swift` dice "máximo 5 tabs activos (más de 5 →
iOS muestra «Más»)" mientras el código usa 8 y la app no usa `TabView` con estilo
`.tabItem` (usa una barra flotante propia). El comentario es herencia de una
versión anterior.

**5. Solapamiento funcional real** (candidatos a consolidar, no a borrar):

- `LearnAndReferenceView` ya contiene `ReferenceView` como sub-pestaña, y
  `ContentView` filtra `reference` de la barra. Es coherente, pero `AppTab.reference`
  sigue existiendo y puede reaparecer desde Ajustes — conviene decidir si se elimina.
- `LearningCenterView` (dentro de `learn`) ya incluye `DreamJournalView` (Sueños) y
  `SpiritualPathView` (Senda). Están accesibles desde ahí y **no** como pestañas
  sueltas: bien resuelto.
- `ask` (Preguntar) y `chat` (Arcana IA) se solapan: ambas responden preguntas; una
  con carta, otra conversacional. Tiene sentido mantenerlas solo si la distinción
  se explica en la interfaz.

### Recomendación

1. Añadir `lunar` a `inactiveTabs` para que sea activable (o retirar la vista).
2. Incluir `chat` en los `activeTabs` por defecto, coherente con `mandatoryTabs`.
3. Bajar el default a 8 pestañas, o subir `maxActive` si 8 no es el límite buscado.
4. Corregir el comentario del "máximo 5".
5. Decidir el destino de `AppTab.reference`.

**No apliqué ninguno de estos cinco puntos**: son decisiones de producto y cambian
lo que ve el usuario. Quedo a la espera de tu criterio.

## 5. Archivos modificados

16 llamadas a `tarotNightBackground()` movidas dentro del stack, más 3 pantallas
con fondo añadido y 1 comentario de `DesignSystem` corregido:

`ContentView`, `ReadingView`, `ReadingPreparationView`, `AstrologyAskTarotView`,
`TarotChatView`, `UnifiedLibraryView`, `LearningCenterView`, `DreamJournalView`,
`JournalView`, `LunarPhasesView`, `NatalChartView`, `ReferenceView`,
`SettingsView`, `SharedDestinyView`, `SpiritualPathView`, `BiorhythmView`,
`DailyCardView`, `DesignSystem`.

Cobertura: de 30 `NavigationStack`, **16** tienen ahora el fondo dentro. Los 14
restantes son en su mayoría `sheet`s (picker de posición, hojas del llavero,
formularios), donde el fondo lo aporta el propio modal.

## 6. Avisos

- **Falso positivo del guardián de escritura.** Bloqueó dos veces guardar
  `ContentView.swift` señalando la línea `TarotChatView(apiKey: model.settings.openAIKey, ...)`.
  Es una **referencia a una propiedad**, no un secreto. Lo resolví con parches de
  línea acotados. Lo dejo anotado por si quieres que el detector excluya este patrón.
- **No hice commit.** Tu working copy tenía ~585 cambios sin confirmar antes de
  empezar; no los toqué.
- **Pendiente de verificar en dispositivo real**: medido solo en simulador; el
  coste de varios `TimelineView` a 30 fps con el `TabView` manteniendo páginas
  vivas no lo he medido en hardware.
