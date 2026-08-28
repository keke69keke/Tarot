# Implementation Plan: ask-tarot-redesign

## Overview

Rediseño exclusivamente visual de `TarotUI/AstrologyAskTarotView.swift`. Se aplican en secuencia los cambios de fondo, glass y colores definidos en el design document, conservando intacta toda la lógica funcional. Sin nuevos archivos, sin nuevos tipos, sin cambios de arquitectura.

## Tasks

- [ ] 1. Añadir `backgroundLayer` a `AskTarotView`
  - [ ] 1.1 Agregar `private var backgroundLayer: some View` con `ZStack { Color.tarotBackground.ignoresSafeArea(); Color.tarotBackgroundGradient.ignoresSafeArea(); AmbientBackgroundView().opacity(0.35) }`
  - [ ] 1.2 Aplicar `.background(backgroundLayer)` sobre el `NavigationStack` en `AskTarotView.body`
  - _Requirements: 1.1, 1.3, 1.5_

- [ ] 2. Actualizar componentes glass en `AskTarotView`
  - [ ] 2.1 Reemplazar el `.background(RoundedRectangle…fill(tarotPanel.opacity(0.92)))` + `.overlay(…LinearGradient…)` de `headerCard` por `.luxuryGlass(cornerRadius: 26)` — conservar todo el contenido interno
  - [ ] 2.2 En `topicChip(_:)`, cambiar el estado seleccionado de `LinearGradient([tarotGold, tarotGoldDeep])` a `Color.tarotGold.opacity(0.22)` fill en `Capsule`, stroke `Color.tarotGold.opacity(0.55)` lineWidth `0.75`, y texto `Color.tarotGold`
  - [ ] 2.3 Reemplazar el fill + stroke del `drawButton` por el patrón glass morado: `Color.white.opacity(0.07)` + `.ultraThinMaterial.opacity(0.5)`, overlay stroke `tarotGold.opacity(0.35)` lineWidth `0.75`, foreground `Color.tarotGold`, shadow `tarotGold.opacity(0.25)` radius `12`, opacity `0.45` cuando vacío/shuffling
  - [ ] 2.4 Reemplazar el container de `answerView` (fill `tarotGold.opacity(0.04)` + LinearGradient stroke) por `.luxuryGlass(cornerRadius: 26)`; reducir el glow `Circle` a `tarotGold.opacity(0.18)` + `blur(radius: 16)`
  - [ ] 2.5 Reemplazar el `.background(Color.tarotPanel.opacity(0.92)).cornerRadius(22)` de `answerSummary` por micro-glass inline: `RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.055))` + `.ultraThinMaterial.opacity(0.45)`, stroke `tarotGold.opacity(0.10)` lineWidth `0.75`
  - _Requirements: 2.1, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 6.1, 6.2, 6.3, 6.4_

- [ ] 3. Añadir `backgroundLayer` a `HoroscopeView`
  - [ ] 3.1 Agregar `private var backgroundLayer: some View` idéntico al de `AskTarotView` (mismo `ZStack`, `AmbientBackgroundView().opacity(0.35)`)
  - [ ] 3.2 Aplicar `.background(backgroundLayer)` sobre el `NavigationStack` en `HoroscopeView.body`
  - _Requirements: 1.2, 1.4, 1.6_

- [ ] 4. Actualizar cards glass en `HoroscopeView`
  - [ ] 4.1 Reemplazar fill + LinearGradient stroke del header card de `HoroscopeView` por `.luxuryGlass(cornerRadius: 26)` — conservar eyebrow "ZODÍACO & TAROT", título y descripción
  - [ ] 4.2 Reemplazar fill `tarotPanel.opacity(0.92)` + LinearGradient stroke + `.shadow(…)` del sign detail card por `.luxuryGlass(cornerRadius: 26)` — conservar separador `Rectangle` interno, toda la información del signo y los toolbar buttons
  - _Requirements: 2.2, 2.4, 7.1, 7.2, 7.3, 7.4_

- [ ] 5. Checkpoint — build limpio y suite de tests
  - Ejecutar `swift build` y confirmar que compila sin errores ni warnings nuevos.
  - Ejecutar `swift test` y confirmar que los 29 tests existentes pasan sin regresiones.
  - _Requirements: 8.4_

## Notes

- Cada tarea opera en un único archivo: `TarotUI/AstrologyAskTarotView.swift`.
- Las sub-tareas de la tarea 2 comparten el mismo scope; aplicarlas en orden descendente dentro del archivo evita conflictos de merge.
- No hay sub-tareas marcadas con `*` porque el design document establece explícitamente que PBT no aplica para este feature (UI rendering / view modifiers) y los tests existentes ya cubren la funcionalidad.
- El checkpoint (tarea 5) valida la ausencia de regresiones funcionales antes de dar por cerrado el feature.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "3.1"] },
    { "id": 2, "tasks": ["2.1", "2.2", "2.3", "3.2"] },
    { "id": 3, "tasks": ["2.4", "4.1"] },
    { "id": 4, "tasks": ["2.5", "4.2"] }
  ]
}
```
