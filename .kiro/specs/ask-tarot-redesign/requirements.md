# Requirements Document

## Introduction

Rediseño visual de `AskTarotView` y `HoroscopeView` (archivo `TarotUI/AstrologyAskTarotView.swift`) para alcanzar paridad visual completa con `TarotChatView` (Arcana IA), que ya implementa el sistema morado lujo minimal. El objetivo es unificar el lenguaje visual de todas las vistas de la app bajo la paleta morada editorial: fondo oscuro `#0F0A22`, acento lavanda `#9984FF`, componentes `luxuryGlass()`, ambiente `AmbientBackgroundView`, tipografía serif con tracking editorial. Toda la lógica funcional existente (horóscopo determinista, draw de carta, temas de consulta, selección de signo zodiacal) se conserva sin modificaciones.

## Glossary

- **AskTarotView**: Vista de consulta al oráculo donde el usuario escribe una pregunta, selecciona un tema y obtiene una carta con interpretación.
- **HoroscopeView**: Vista de horóscopo diario que permite seleccionar un signo zodiacal y muestra la lectura astral del día.
- **TarotChatView**: Vista de referencia (Arcana IA) que ya implementa el sistema morado lujo con `AmbientBackgroundView` y `luxuryGlass()`.
- **luxuryGlass**: Modificador de vista definido en `DesignSystem.swift` que aplica `Color.white.opacity(0.055)` + `.ultraThinMaterial.opacity(0.55)` + stroke `tarotGold.opacity(0.13)` hairline `0.75pt` + sombras premium.
- **AmbientBackgroundView**: Componente de fondo con 19 estrellas de 0.9px y 6 motas de polvo sutil sobre el gradiente oscuro.
- **tarotGold**: Color lavanda `#9984FF` — acento principal de la paleta morada.
- **tarotBackground**: Color de fondo `#0F0A22`.
- **tarotPanel**: Color de panel vidrio semitransparente.
- **tarotBorder**: Color de marco hairline sutil.
- **topicChip**: Pastilla de selección de tema en `AskTarotView` (General, Amor, Trabajo, Dinero, Decisión Sí/No).
- **headerCard**: Contenedor de encabezado con eyebrow label, título y descripción.
- **answerView**: Contenedor de respuesta que muestra la carta obtenida con su interpretación.
- **drawButton**: Botón principal de `AskTarotView` que lanza la consulta al oráculo.
- **signDetailCard**: Tarjeta de detalle del signo zodiacal seleccionado en `HoroscopeView`.

---

## Requirements

### Requirement 1: Fondo global con ambiente morado

**User Story:** Como usuario de la app, quiero que `AskTarotView` y `HoroscopeView` tengan el mismo fondo atmosférico morado que `TarotChatView`, para que todas las vistas se sientan parte de la misma experiencia de lujo.

#### Acceptance Criteria

1. THE `AskTarotView` SHALL renderizar un `ZStack` base con `Color.tarotBackground`, `Color.tarotBackgroundGradient` y `AmbientBackgroundView` con opacidad `0.35`.
2. THE `HoroscopeView` SHALL renderizar el mismo `ZStack` base con `Color.tarotBackground`, `Color.tarotBackgroundGradient` y `AmbientBackgroundView` con opacidad `0.35`.
3. WHEN `AskTarotView` se presenta, THE `AskTarotView` SHALL mostrar el fondo antes de cualquier contenido de scroll.
4. WHEN `HoroscopeView` se presenta, THE `HoroscopeView` SHALL mostrar el fondo antes de cualquier contenido de scroll.
5. THE `AskTarotView` SHALL usar `.ignoresSafeArea()` en las capas de fondo para cubrir el área completa de la pantalla.
6. THE `HoroscopeView` SHALL usar `.ignoresSafeArea()` en las capas de fondo para cubrir el área completa de la pantalla.

---

### Requirement 2: headerCard con luxuryGlass

**User Story:** Como usuario, quiero que los encabezados de ambas vistas usen el componente `luxuryGlass()` para que se vean consistentes con el resto de la app.

#### Acceptance Criteria

1. THE `AskTarotView.headerCard` SHALL aplicar el modificador `.luxuryGlass(cornerRadius: 26)` en lugar de los fondos sólidos `tarotPanel.opacity(0.92)` actuales.
2. THE `HoroscopeView` header card SHALL aplicar el modificador `.luxuryGlass(cornerRadius: 26)` en lugar de los fondos sólidos actuales.
3. THE `AskTarotView.headerCard` SHALL eliminar el stroke con gradiente `LinearGradient` oro/burgundy y usar únicamente el stroke hairline incluido en `luxuryGlass()`.
4. THE `HoroscopeView` header card SHALL eliminar el stroke con gradiente `LinearGradient` oro/burgundy y usar únicamente el stroke hairline incluido en `luxuryGlass()`.
5. THE `AskTarotView.headerCard` SHALL conservar el eyebrow label ("CONSULTA AL ORÁCULO"), el título serif y el texto descriptivo sin modificaciones de contenido.
6. THE `HoroscopeView` header card SHALL conservar el eyebrow label ("ZODÍACO & TAROT"), el título serif y el texto descriptivo sin modificaciones de contenido.

---

### Requirement 3: topicChip con fill lavanda (AskTarotView)

**User Story:** Como usuario, quiero que las pastillas de selección de tema usen el color lavanda coherente con el sistema morado, en lugar del gradiente dorado sólido actual.

#### Acceptance Criteria

1. WHEN un `topicChip` está seleccionado, THE `AskTarotView` SHALL aplicar `Color.tarotGold.opacity(0.22)` como fill del `Capsule` en lugar del `LinearGradient` de colores `[tarotGold, tarotGoldDeep]`.
2. WHEN un `topicChip` está seleccionado, THE `AskTarotView` SHALL aplicar un stroke `Color.tarotGold.opacity(0.55)` con lineWidth `0.75` visible.
3. WHEN un `topicChip` está seleccionado, THE `AskTarotView` SHALL mostrar el texto en `Color.tarotGold` (lavanda).
4. WHEN un `topicChip` NO está seleccionado, THE `AskTarotView` SHALL conservar el fill `tarotPanel.opacity(0.9)` y stroke `tarotGold.opacity(0.25)` actuales.
5. THE `AskTarotView` SHALL conservar la lógica de animación `.spring(response: 0.3, dampingFraction: 0.7)` al cambiar la selección.

---

### Requirement 4: drawButton con estilo luxuryGlass morado

**User Story:** Como usuario, quiero que el botón "Consultar Tarot" use el sistema de glass morado en lugar del gradiente dorado sólido, para mantener coherencia visual con el resto de la app.

#### Acceptance Criteria

1. THE `AskTarotView.drawButton` SHALL reemplazar el fill con `LinearGradient([tarotGold, tarotGoldDeep])` por el patrón `luxuryGlass`: `Color.white.opacity(0.07)` + `.ultraThinMaterial.opacity(0.5)` + stroke `tarotGold.opacity(0.35)` lineWidth `0.75`.
2. THE `AskTarotView.drawButton` SHALL mostrar el texto e ícono en `Color.tarotGold` (lavanda) en lugar de `Color.tarotBackground`.
3. THE `AskTarotView.drawButton` SHALL agregar un glow sutil `shadow(color: tarotGold.opacity(0.25), radius: 12)` al estar habilitado.
4. WHEN `drawButton` está deshabilitado (pregunta vacía o `isShuffling`), THE `AskTarotView` SHALL reducir la opacidad general del botón a `0.45`.
5. THE `AskTarotView.drawButton` SHALL conservar toda la lógica funcional: validación de pregunta vacía, haptic `.medium`, delay `1.2s`, `randomElement()`, `playGoldenChime()`.

---

### Requirement 5: shufflingView con glow morado

**User Story:** Como usuario, quiero que la animación de barajado use tonos morados para continuar la experiencia visual coherente.

#### Acceptance Criteria

1. THE `AskTarotView.shufflingView` SHALL conservar las tres `CardFace` con rotación y offset existentes.
2. THE `AskTarotView.shufflingView` SHALL conservar la animación `.easeInOut(duration: 0.5).repeatForever(autoreverses: true)`.
3. THE `AskTarotView.shufflingView` SHALL conservar el texto "Barajando las cartas..." en `Color.tarotGold.opacity(0.88)`.

---

### Requirement 6: answerView con luxuryGlass y glow morado sutil

**User Story:** Como usuario, quiero que la vista de respuesta tenga el acabado glass morado premium para que el resultado de la consulta se sienta especial y coherente.

#### Acceptance Criteria

1. THE `AskTarotView.answerView` SHALL reemplazar el fill sólido `tarotGold.opacity(0.04)` por `.luxuryGlass(cornerRadius: 26)`.
2. THE `AskTarotView.answerView` SHALL eliminar el stroke `LinearGradient` oro/burgundy existente (ya incluido en `luxuryGlass()`).
3. THE `AskTarotView.answerView` glow `Circle` SHALL cambiar de `tarotGold.opacity(0.30)` con `blur(radius: 20)` a `tarotGold.opacity(0.18)` con `blur(radius: 16)` para un efecto más sutil.
4. THE `AskTarotView.answerSummary` SHALL reemplazar el fill `tarotPanel.opacity(0.92)` por el patrón glass: `Color.white.opacity(0.055)` + `.ultraThinMaterial.opacity(0.45)` + stroke `tarotGold.opacity(0.10)` lineWidth `0.75`.
5. THE `AskTarotView.answerView` SHALL conservar el header "RESPUESTA DEL TAROT", la `CardFace`, el nombre de la carta, la lógica de topic "Decisión Sí/No" y la interpretación.
6. THE `AskTarotView.answerView` SHALL conservar la transición `.opacity.combined(with: .scale(scale: 0.95))`.

---

### Requirement 7: signDetailCard de HoroscopeView con luxuryGlass

**User Story:** Como usuario, quiero que la tarjeta de detalle del signo zodiacal use luxuryGlass para verse coherente con el resto de la app.

#### Acceptance Criteria

1. THE `HoroscopeView` sign detail card SHALL aplicar `.luxuryGlass(cornerRadius: 26)` en lugar del fill `tarotPanel.opacity(0.92)` + stroke `LinearGradient` actuales.
2. THE `HoroscopeView` sign detail card SHALL eliminar el stroke `LinearGradient` oro/burgundy existente (ya incluido en `luxuryGlass()`).
3. THE `HoroscopeView` sign detail card SHALL conservar el separador `Rectangle` con `LinearGradient` lavanda sutil existente.
4. THE `HoroscopeView` sign detail card SHALL conservar toda la información: símbolo, nombre, fechas, elemento, "Lectura de Hoy", `dailyHoroscopeText(for:)` y `dateString(for:)`.
5. THE `HoroscopeView` sign selector (grid horizontal de signos) SHALL conservar su lógica de selección con `tarotGold.opacity(0.24)` fill y stroke `tarotGold` lineWidth `1.2` cuando está seleccionado.

---

### Requirement 8: Preservación de lógica funcional completa

**User Story:** Como desarrollador, quiero que el rediseño sea exclusivamente visual para que no se introduzcan regresiones en la funcionalidad existente.

#### Acceptance Criteria

1. THE `AskTarotView` SHALL conservar sin modificaciones el `ZodiacSign` enum, `dailyHoroscopeText(for:)`, `dateString(for:)` y todas las propiedades computadas.
2. THE `AskTarotView` SHALL conservar el flujo completo de draw: pregunta → shuffle → `repository.allCards().randomElement()` → reveal con spring.
3. THE `HoroscopeView` SHALL conservar la lógica determinista de horóscopo diario basada en `Calendar.ordinality` y `seed % 5`.
4. WHEN las pruebas de la suite `TarotCoreTests` y `TarotDataTests` se ejecutan tras el rediseño, THE Test_Suite SHALL pasar los 29 tests existentes sin regresiones.
5. THE `AskTarotView` SHALL conservar el soporte multiplataforma `#if os(iOS)` para `navigationBarTitleDisplayMode(.inline)`.
6. THE `HoroscopeView` SHALL conservar el toolbar button "Actualizar" con `arrow.clockwise` que actualiza `today = Date()`.
