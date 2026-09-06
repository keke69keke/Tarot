# Design Document — ask-tarot-redesign

## Overview

Rediseño exclusivamente visual de `AskTarotView` y `HoroscopeView` en `TarotUI/AstrologyAskTarotView.swift` para alcanzar paridad estética completa con `TarotChatView` (Arcana IA). El cambio unifica el lenguaje visual de toda la app bajo la paleta morada editorial: fondo atmosférico con `AmbientBackgroundView`, componentes con `luxuryGlass()`, y colores lavanda `#9984FF` como acento. Toda la lógica funcional existente se preserva sin modificaciones.

### Principios del rediseño

- **Una sola operación de cirugía visual**: se modifica `AstrologyAskTarotView.swift` únicamente.
- **Sin regresiones funcionales**: la lógica de draw, horóscopo determinista, y todos los tests existentes deben pasar intactos.
- **Consistencia de sistema**: reutilizar `luxuryGlass()`, `AmbientBackgroundView` y los color tokens ya definidos en `DesignSystem.swift`.
- **Eliminación de gradientes dorado-burgundy**: reemplazar todos los `LinearGradient([tarotGold, tarotBurgundy])` de stroke por el hairline `0.75pt` ya incluido en `luxuryGlass()`.

---

## Architecture

La arquitectura de las vistas permanece sin cambios estructurales. La intervención es de nivel de **view modifier** y **background layer**.

```
NavigationStack
└── ZStack                          ← NUEVO: envoltura de fondo
    ├── backgroundLayer             ← NUEVO: Color.tarotBackground +
    │   ├── Color.tarotBackground   │         tarotBackgroundGradient +
    │   ├── Color.tarotBackgroundGradient  │  AmbientBackgroundView(0.35)
    │   └── AmbientBackgroundView(0.35)
    └── ScrollView                  ← existente (sin cambios)
        └── VStack
            ├── headerCard          ← luxuryGlass(cornerRadius: 26)
            ├── topicSelector       ← topicChip actualizado
            ├── questionInput       ← sin cambios
            ├── drawButton          ← patrón glass morado
            ├── shufflingView?      ← sin cambios
            └── answerView?         ← luxuryGlass + glow reducido
```

### Decisión de arquitectura: ZStack vs `.background()`

Se usa `.background(backgroundLayer)` en el `NavigationStack` siguiendo el patrón exacto de `TarotChatView`, en lugar de añadir un `ZStack` wrapper externo. Esto evita interferir con la navegación de SwiftUI y garantiza que `ignoresSafeArea()` se aplique correctamente en capas de fondo.

---

## Components and Interfaces

### 1. `backgroundLayer` (private var, nuevo en ambas vistas)

Patrón idéntico al de `TarotChatView.backgroundGradient`:

```swift
private var backgroundLayer: some View {
    ZStack {
        Color.tarotBackground.ignoresSafeArea()
        Color.tarotBackgroundGradient.ignoresSafeArea()
        AmbientBackgroundView().opacity(0.35)
    }
}
```

Se aplica como `.background(backgroundLayer)` sobre el `NavigationStack`. La opacidad es `0.35` (vs `0.45` en TarotChatView) para que el fondo sea ligeramente más tranquilo en las vistas de consulta, que tienen más contenido de lectura.

### 2. `headerCard` — AskTarotView (modificado)

**Antes:**
```swift
.background(RoundedRectangle(...).fill(Color.tarotPanel.opacity(0.92)))
.overlay(RoundedRectangle(...).stroke(LinearGradient([tarotGold, tarotBurgundy]), lineWidth: 1))
```

**Después:**
```swift
.luxuryGlass(cornerRadius: 26)
```

El contenido interno (eyebrow "CONSULTA AL ORÁCULO", título serif, descripción) permanece intacto.

### 3. `topicChip` — AskTarotView (modificado, estado seleccionado)

**Estado seleccionado — antes:**
- Fill: `LinearGradient([tarotGold, tarotGoldDeep])`
- Stroke: `Color.clear`
- Texto: `Color.tarotBackground`

**Estado seleccionado — después:**
- Fill: `Color.tarotGold.opacity(0.22)` sobre `Capsule`
- Stroke: `Color.tarotGold.opacity(0.55)` lineWidth `0.75`
- Texto: `Color.tarotGold`

**Estado no seleccionado:** sin cambios (`tarotPanel.opacity(0.9)` fill, `tarotGold.opacity(0.25)` stroke).

La animación `.spring(response: 0.3, dampingFraction: 0.7)` se preserva.

### 4. `drawButton` — AskTarotView (modificado)

**Antes:** fill `LinearGradient([tarotGold, tarotGoldDeep])`, texto `tarotBackground`, shadow gold sólido.

**Después — patrón glass morado:**
```swift
.background(
    RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Color.white.opacity(0.07))
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
)
.overlay(
    RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.tarotGold.opacity(0.35), lineWidth: 0.75)
)
.foregroundStyle(Color.tarotGold)
.shadow(color: Color.tarotGold.opacity(0.25), radius: 12)
.opacity(question.isEmpty || isShuffling ? 0.45 : 1.0)
```

Toda la lógica funcional del botón (validación, haptic, delay 1.2s, `randomElement()`, `playGoldenChime()`) se preserva sin tocar.

### 5. `answerView` — AskTarotView (modificado)

**Container — antes:** fill `tarotGold.opacity(0.04)` + stroke LinearGradient.

**Container — después:**
```swift
.luxuryGlass(cornerRadius: 26)
```

**Glow Circle — antes:** `tarotGold.opacity(0.30)` + `blur(radius: 20)`.

**Glow Circle — después:** `tarotGold.opacity(0.18)` + `blur(radius: 16)` (efecto más sutil, no compite con el glass del contenedor).

**Transición:** `.opacity.combined(with: .scale(scale: 0.95))` se preserva.

### 6. `answerSummary` — AskTarotView (modificado)

**Antes:** `.background(Color.tarotPanel.opacity(0.92))` + `.cornerRadius(22)` (sin overlay).

**Después — micro-glass manual** (el `cornerRadius` de la cápsula interior difiere del `answerView` outer, por eso usamos el patrón inline en lugar de `luxuryGlass()`):
```swift
.background(
    RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color.white.opacity(0.055))
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.45)
        )
)
.overlay(
    RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(Color.tarotGold.opacity(0.10), lineWidth: 0.75)
)
```

El contenido interno (question quote, divider, interpretación, lógica Decisión Sí/No) permanece intacto.

### 7. `HoroscopeView` — header card (modificado)

Mismo tratamiento que `AskTarotView.headerCard`: reemplazar fill + LinearGradient stroke por `.luxuryGlass(cornerRadius: 26)`. Eyebrow "ZODÍACO & TAROT", título y descripción se preservan.

### 8. `HoroscopeView` — sign detail card (modificado)

**Antes:** fill `tarotPanel.opacity(0.92)` + stroke `LinearGradient([tarotGold, tarotBurgundy])` + `.shadow(...)`.

**Después:**
```swift
.luxuryGlass(cornerRadius: 26)
```

El separador `Rectangle` con `LinearGradient` lavanda sutil (ya existente) se conserva — es decoración interna que no forma parte del stroke del card.

### 9. `HoroscopeView` — sign selector chips (sin cambios)

Los chips de selección de signo zodiacal ya usan `tarotGold.opacity(0.24)` fill + stroke `tarotGold` lineWidth `1.2` cuando seleccionados. Son correctos para el sistema morado y no se tocan.

---

## Data Models

Este rediseño no introduce ni modifica ningún modelo de datos. Los tipos `Card`, `ZodiacSign`, `CardRepository`, `TarotAudioService` permanecen intactos.

---

## Error Handling

Al ser un rediseño puramente visual sin nuevas operaciones asíncronas ni I/O, no se introducen nuevas rutas de error. Los errores existentes (repositorio vacío en `randomElement()`, etc.) ya están manejados en la lógica original que se preserva.

---

## Testing Strategy

### Applicability de Property-Based Testing

Este feature **no es candidato para PBT**. Se trata de UI rendering y aplicación de view modifiers de SwiftUI — no hay funciones puras con input/output, ni transformaciones de datos, ni lógica de negocio nueva. PBT no aplica según las reglas:

> *UI rendering and layout — use snapshot tests and visual regression tests instead.*

### Estrategia de testing

**Tests de regresión (existentes — deben pasar sin cambios):**
- `TarotCoreTests` (29 tests): lógica de cartas, interpretaciones, repositorio.
- `TarotDataTests`: modelos y persistencia.

Estos tests no tocan código de UI, por lo que el rediseño no los afecta estructuralmente. El comando de verificación:
```
swift test --filter TarotCoreTests
swift test --filter TarotDataTests
```

**Tests de snapshot (recomendados, no existentes aún):**

Para proteger la paridad visual a futuro, se recomienda añadir snapshot tests con una librería como [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing):

- Snapshot de `AskTarotView` estado inicial (sin carta dibujada).
- Snapshot de `AskTarotView` con topicChip "Amor" seleccionado.
- Snapshot de `AskTarotView` con `answerView` visible (carta mock).
- Snapshot de `HoroscopeView` con signo "Leo" seleccionado.

Estos snapshots se generan una vez tras el rediseño y sirven como línea base para detectar regresiones visuales futuras.

**Tests de ejemplo (manuales / en simulador):**
- Verificar que `AmbientBackgroundView` es visible detrás del scroll en ambas vistas.
- Verificar que el glow del `drawButton` aparece solo cuando la pregunta no está vacía.
- Verificar que el chip seleccionado muestra fill lavanda translúcido, no gradiente sólido.
- Verificar que la opacidad del `drawButton` baja a `0.45` cuando `question.isEmpty`.

### Build verification

Tras aplicar los cambios, verificar build limpio:
```
swift build
```
Y correr la suite completa:
```
swift test
```
Ambos deben completarse sin errores ni warnings nuevos.
