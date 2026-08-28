# Requirements Document — polish-cohesion

## Introduction

Análisis completo de la app Tarot (build ✅, tests ✅ 2026-08-28). El sistema morado lujo se aplicó ya a las vistas principales (`DailyCardView`, `ReadingView`, `WelcomeView`, `AskTarotView`, `HoroscopeView`, `TarotChatView`, `UnifiedLibraryView`, `NatalChartView`, `BiorhythmView`, `SettingsView`), pero quedan **restos del sistema anterior** (oro joya, fuentes del sistema, `.primary`/`.secondary` adaptativos, emojis de color, código muerto) y **bugs de UX** (Welcome no persistente, tabs >5). Este spec unifica la cohesión visual y funcional de toda la app bajo el lenguaje: fondo `#0F0A22`, acento lavanda `#9984FF`, `luxuryGlass()`, tipografía serif con tracking editorial, **sin emojis de color** (glifos monocromos), dark mode forzado.

## Glossary

- **Sistema lujo**: design system morado (`DesignSystem.swift` + `Platform.swift`) — `LuxuryGlass`, `EyebrowLabel`, `GoldDivider`, `LuxurySpacing/Radius/Animation`, fuentes serif editorial, `AmbientBackgroundView`.
- **Estilo legado**: uso de `.primary`/`.secondary`, `.font(.title)/.subheadline/.caption` del sistema, `cornerRadius()`, emojis de color, fills dorados joya.
- **tarotGold**: lavanda `#9984FF` (acento).
- **tarotIvory**: `#F5F1E8` (texto).
- **hasSeenWelcome**: flag persistente para mostrar WelcomeView solo en el primer arranque.
- **TabView >5**: iOS agrupa en pestaña "Más" cuando hay más de 5 tabs activos.

---

## Requirements

### Requirement 1: Marcos de cartas lavanda (eliminar oro joya)

**User Story:** Como usuario, quiero que todas las cartas tengan el marco lavanda del sistema, no el oro champagne del diseño anterior, para que la app se sienta cohesiva.

#### Acceptance Criteria

1. THE `CardFace.swift` SHALL usar `tarotGoldGradient` (o `tarotGoldHighlight`/`tarotGold`/`tarotGoldDeep`) en el marco exterior tipo foil, en lugar de los RGB dorados joya actuales (`Color(red: 0.92, green: 0.80, blue: 0.45)` y similares).
2. THE marco interior hairline SHALL usar `tarotGold.opacity(0.50)`.
3. THE cambios NO SHALL afectar el render de las imágenes de cartas ni la textura del reverso.
4. THE `CardBackView` SHALL permanecer coherente con la paleta lavanda (auditar el diseño actual).

### Requirement 2: Eliminar `.primary`/`.secondary` y fuentes del sistema

**User Story:** Como usuario, quiero que todos los textos usen la misma voz editorial serif ivory, sin grises adaptativos del sistema que rompen la atmósfera nocturna.

#### Acceptance Criteria

1. THE siguientes vistas SHALL reemplazar `foregroundStyle(.primary)` → `Color.tarotIvory` y `.secondary` → `Color.tarotIvory.opacity(0.58)`:
   - `RiderReferenceView.swift`
   - `SecretVaultView.swift`
   - `PDFReaderView.swift`
   - `MysticMusicPlayerBar.swift`
   - `CardDetailView.swift`
   - `CardWisdomView.swift`
   - `JournalDetail.swift`
   - `SpreadNarrativeCard.swift`
   - `LibraryGridView.swift` (solo si no se elimina en R9)
2. THE `.font(.title)/.title2/.headline/.subheadline/.caption` del sistema en estas vistas SHALL reemplazarse por las variantes serif (`.system(size:…, design: .serif)`) con tracking/lineSpacing editorial.
3. THE header de `RiderReferenceView` SHALL migrar a header editorial: `EyebrowLabel` + título serif custom + descripción ivory + `luxuryGlass`.
4. THE `SecretVaultView` SHALL usar `luxuryGlass()` en el keypad y paneles, icono `lock.shield` con `.font(.thin)` y textos serif.

### Requirement 3: Paleta de sabiduría de carta monocroma

**User Story:** Como usuario, quiero que los chips de "Sabiduría de la Carta" (astrología, cábala, numerología…) usen tonos lavanda del sistema, no rojos/verdes/azules saturados que rompen el minimalismo.

#### Acceptance Criteria

1. THE `CardWisdomView.swift` SHALL mapear todos los colores RGB vivos a variaciones de la paleta (`tarotGold`, `tarotGoldHighlight`, `tarotGoldDeep`, `tarotBurgundy`) con opacidades 0.14/0.06/0.18 como hoy.
2. THE estructura de items (icono, título, valor) SHALL conservarse intacta.

### Requirement 4: Sin emojis de color — glifos monocromos

**User Story:** Como usuario, quiero leer texto limpio sin emoji color, consistente con el lenguaje visual (glifos spread `○◇✚` en lavanda).

#### Acceptance Criteria

1. THE `AstrologyAskTarotView.dailyHoroscopeText` SHALL reemplazar `🎴` y `🔢` por glifos/SF Symbols neutros en lavanda o texto plano tipográfico (p. ej. `◈ Carta guía:` y `✦ Números:`).
2. THE veredicto Sí/No SHALL reemplazar `✨ SÍ` / `⚖️ Depende` por `◈ SÍ (Muy Favorable)` / `◇ Depende de tu voluntad` (o similar monocromo).
3. THE `TarotViewModel.saveSpread` y `SpreadNarrativeCard` SHALL reemplazar `🎯` por `◈` (u otro glifo).
4. THE `RiderReferenceView` disclosure `🎴` → `◇` (o `▸`/`✦`).
### Requirement 5: Welcome solo en primer arranque (bug UX)

**User Story:** Como usuario, quiero ver la pantalla de bienvenida la primera vez y entrar directo a la app después, sin que "Las cartas te esperan" bloquee cada apertura.

#### Acceptance Criteria

1. THE `ContentView` SHALL persistir un flag `hasSeenWelcome` (en `UserDefaults` vía un helper, o en `UserSettings` + `SettingsRepository`).
2. WHEN el flag es `true`, THE `ContentView` SHALL iniciar con `showWelcome = false` (sin overlay).
3. WHEN el usuario pulsa "Iniciar lectura" (o cierra Welcome), THE flag SHALL guardarse.
4. THE comportamiento NO SHALL romper el `preferredColorScheme(.dark)` ni la animación de transición.

### Requirement 6: Límite de tabs activos a 5

**User Story:** Como usuario, quiero que el menú inferior muestre mis 5 tabs sin que iOS lo convierta en "Más" silenciosamente.

#### Acceptance Criteria

1. THE `SettingsView` SHALL limitar `activeTabs` a un máximo de 5.
2. THE reubicación de un tab oculto a activo SHALL no exceder 5 (bloquear con haptic + indicación visual si se intenta el 6º).
3. THE `UserDefaultsSettingsRepository` SHALL continuar migrando/recortando a 5 si el arreglo persistido trae más.

### Requirement 7: Persistencia unificada Biorhythm/Natal

**User Story:** Como usuario, quiero que mi fecha de nacimiento se guarde igual que el resto de ajustes, sin claves sueltas.

#### Acceptance Criteria

1. THE `BiorhythmView` y `NatalChartView` SHALL guardar/leer `birthDate`/`birthTime`/`place` desde `UserSettings` (via `TarotViewModel/container.settings` o `AppContainer`) en lugar de `UserDefaults.standard.object(forKey:)` directo.
2. THE campos ya existen en `UserSettings` (`biorhythmBirthDate`, `natalBirthDate`, `natalBirthTime`, `natalPlace`) — NO añadir claves nuevas.
3. THE `onChange` SHALL persistir vía `settings.save`.

### Requirement 8: Strings hardcodeadas → TarotStrings

**User Story:** Como desarrollador y usuario, quiero que todos los textos estén centralizados en `TarotStrings` para localización futura.

#### Acceptance Criteria

1. THE siguientes vistas SHALL mover sus literales a `TarotStrings`: `AskTarotView` (títulos, topics, placeholder, botón, veredicto, estados), `HoroscopeView` (eyebrow, descripción, "Elemento:", "Lectura de Hoy", botón actualizar), `DailyCardView` (subtítulos, "REVELAR", estados), `TarotChatView` (welcome banner, placeholder, botones), `SecretVaultView` (PIN view, botones), `ReadingView` (textos restantes sin localizar).
2. THE casos restantes con `Text("...")` directo en español SHALL añadirse como keys.

### Requirement 9: Código muerto

**User Story:** Como desarrollador, quiero mantener el codebase limpio y sin archivos sin uso que confunden.

#### Acceptance Criteria

1. THE `LibraryGridView.swift` (sin referencias — `UnifiedLibraryView` la reemplaza) SHALL eliminarse del target `TarotUI`.
2. THE eliminación NO SHALL romper el build (verificar con `swift build`).

### Requirement 10: Filas del Diario con miniaturas de carta

**User Story:** Como usuario, quiero reconocer de un vistazo qué cartas guardé en el diario.

#### Acceptance Criteria

1. THE `JournalView` list rows SHALL mostrar un `CardFace` miniatura (p. ej. 40×60) de la primera carta de cada entrada guardada (o las cartas en fila horizontal discreta).
2. THE layout de la fila SHALL conservar eyebrow + fecha + separador + nombres, sin sobrecargar.

### Requirement 11: Compartir Carta del Día

**User Story:** Como usuario, quiero compartir la carta del día como imagen elegante (ShareLink).

#### Acceptance Criteria

1. THE `DailyCardView` tras revelar SHALL mostrar un botón "Compartir" (icono `square.and.arrow.up` thin, estilo glass morado).
2. THE share SHALL exportar una captura/`ImageRenderer` de la carta + nombre + mensaje corto (o al menos el texto con la carta vía `ShareLink`).
3. THE botón NO SHALL romper la animación actual de revelado.

### Requirement 12: Iconos thin y haptics consistentes

**User Story:** Como usuario, quiero iconos finos (thin) y una respuesta háptica consistente en las acciones clave.

#### Acceptance Criteria

1. THE iconos filled que quedan en CTAs SHALL pasar a `.light`/`.thin`: `hand.tap.fill` → `hand.tap` (AskTarotView), `lock.shield.fill` → `lock.shield` (SecretVaultView), `star.fill`/`moon.stars.fill` en headers → thin cuando son decorativos.
2. THE `TarotAudioService.shared.triggerHaptic` SHALL llamarse en acciones clave faltantes: guardar lectura, revelar todas, borrar entrada del diario, cambiar tab.
3. THE haptics NO SHALL añadirse en interacciones de alta frecuencia (scroll, typing).

### Requirement 13: Pausar atmósfera en background

**User Story:** Como usuario, quiero que el fondo animado no consuma batería cuando la app está en segundo plano.

#### Acceptance Criteria

1. THE `AmbientBackgroundView` SHALL pausar sus `TimelineView` cuando `scenePhase` no es `.active` (o el contenedor evaluado lo excluya).
2. THE implementación SHALL ser ligera (una `@Environment(\.scenePhase)` en la vista o en el `ContentView` y condición de render).

### Requirement 14: Checkpoint global

#### Acceptance Criteria

1. THE `swift build` SHALL compilar sin errores tras cada wave.
2. THE `swift test` SHALL pasar 29/29 sin regresiones tras cada wave.
3. THE app en simulador SHALL verificar: Biblioteca, Referencia, Diario, Hoy, Tirada, Preguntar, Horóscopo, Ajustes con nueva cohesión.
5. THE respuestas de IA en `TarotChatView` (✨🌟 en `localTarotResponse`) SE PUEDEN conservar como voz de personaje "Arcana" (decisión de producto), pero el resto de la app no usa emoji.