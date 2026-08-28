# Implementation Plan: polish-cohesion

## Overview

Unificación visual y funcional de toda la app bajo el sistema morado lujo, resolviendo los restos del diseño anterior (oro joya, estilos del sistema, emojis, código muerto) y los bugs de UX detectados (Welcome no persistente, tabs >5, persistencia duplicada). Tres olas: **1. Cohesión visual · 2. UX/arquitectura · 3. Features/polish**. Cada ola termina en checkpoint build+tests sin regresiones.

## Diagnóstico (2026-08-28)

- **Build**: ✅ `swift build` — 16s sin errores.
- **Tests**: ✅ `swift test` — sin regresiones.
- **Sistema lujo ya aplicado en**: DailyCard, Reading, Welcome, Ask/Horoscope, Chat, UnifiedLibrary, Natal, Biorhythm, Settings, ContentView (dark forced).
- **Restos legado** (ver requirements): CardFace (oro joya), .primary/.secondary en 8+ vistas, fuentes del sistema, emojis de color, `LibraryGridView` muerto, strings hardcodeadas.
- **Bugs UX**: Welcome siempre al arrancar (`ContentView.showWelcome = true`), tabs >5 → "Más" de iOS, Biorhythm/Natal persisten con UserDefaults sueltos.

## Tasks

### Wave 1 — Cohesión visual

- [x] 1. `CardFace.swift` — marco foil oro → lavanda (`tarotGoldGradient`), hairline interior → `tarotGold.opacity(0.50)`. _Req: R1_
- [x] 2. `CardWisdomView.swift` — colores RGB vivos → tonos lavanda monocromos. _Req: R3_
- [x] 3. `RiderReferenceView.swift` — header editorial + `luxuryGlass` + `.primary/.secondary` → ivory; fonts sistema → serif. _Req: R2_
- [x] 4. `SecretVaultView.swift` — keypad/paneles `luxuryGlass`, icono `lock.shield` thin, textos serif; `primary/secondary` → ivory. _Req: R2, R12_
- [x] 5. `CardDetailView.swift` + `TarotChatView` + `JournalDetail` + `SpreadNarrativeCard` + `MysticMusicPlayerBar` + `PDFReaderView` — `primary/secondary` → ivory; fonts sistema → serif. _Req: R2_
- [x] 6. Emojis color → glifos monocromos (`AstrologyAskTarotView`, `TarotViewModel`, `SpreadNarrativeCard`, `RiderReferenceView`). _Req: R4_
- [x] 7. Iconos filled decorativos → thin/light (`hand.tap.fill`, `lock.shield.fill`, `star.fill` decorativos). _Req: R12_

**Checkpoint 1** ✅ (build 23.5s OK · tests OK · 2026-08-28): `swift build` ✅ + `swift test` ✅ + verificación visual en simulador (Biblioteca, Diario, Referencia, Bóveda).

### Wave 2 — UX y arquitectura

- [x] 8. `ContentView` — Welcome persistente (`hasSeenWelcome` en UserDefaults/Settings): solo primer arranque. _Req: R5_
- [x] 9. `SettingsView` + `UserDefaultsSettingsRepository` — límite `activeTabs ≤ 5` (`clampTabs` en load+save, bloqueo en UI, migración de instalaciones legacy; +3 tests unitarios). _Req: R6_
- [x] 10. `BiorhythmView` + `NatalChartView` — persistencia vía `UserSettings`/repository, sin UserDefaults sueltos (init con `model`, persist en `onChange`). _Req: R7_
- [x] 11. Eliminar `LibraryGridView.swift` (código muerto, sin referencias). _Req: R9_
- [x] 12. Strings hardcodeadas → `TarotStrings` (`hiddenTabsHint`, títulos Biorritmo/Hoja Natal). _Req: R8_

**Checkpoint 2** ✅ (2026-08-28): `swift build` ✅ (131s) · `swift test` ✅ (suite Settings 9/9 con 3 tests nuevos de clampTabs) · migración transparente: las claves legacy `biorhythmBirthDate`/`natal*` coinciden con las del repository, sin pérdida de datos.

### Wave 3 — Features y polish

- [x] 13. `JournalView` — miniaturas `CardFace` en las filas del diario (hasta 5, con excedente "+N"). _Req: R10_
- [x] 14. `DailyCardView` — botón **Compartir** (`ShareLink`) tras revelar ("◈ Carta del día: …") + haptic al revelar. _Req: R11_
- [x] 15. Haptics consistentes (`TarotAudioService.triggerHaptic`) en: revelar todas (tirada, `.medium`), guardar lectura (`.success`), borrar entrada (diario, `.medium`), cambiar tab (`ContentView` con `TabView(selection:)`, `.light`). `AppTab` → `Hashable`. _Req: R12_
- [x] 16. `AmbientBackgroundView` — TimelineViews se pausan cuando `scenePhase ≠ .active` (canvas refactorizado a `starField`/`dustField`, frame estático en background). _Req: R13_

**Checkpoint 3 (final)** ✅ (2026-08-28): `swift build` ✅ (96.8s) · `swift test` ✅ 32/32 · memoria `Cerebro/Tarot/Estado-Actual.md` y `Contexto.md` actualizadas. **Spec `polish-cohesion` COMPLETO (16/16 tareas, R1–R14).**

## Notes

- Wave 1 es quirúrgica y de bajo riesgo: cambia colores/fuentes sin tocar lógica. Prioridad para impacto visual inmediato.
- Wave 2 incluye los 2 bugs de comportamiento notables (Welcome y tabs) — alta prioridad de producto.
- La R12 (haptics) es transversal; no añadir haptics en scroll/typing.
- Los emojis de IA en `TarotChatView` (`✨🌟`) se conservan por decisión de producto (voz de "Arcana").

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "2"] },
    { "id": 1, "tasks": ["3", "4", "5"] },
    { "id": 2, "tasks": ["6", "7"] },
    { "id": 3, "tasks": ["8", "9"] },
    { "id": 4, "tasks": ["10", "11", "12"] },
    { "id": 5, "tasks": ["13", "14", "15", "16"] }
  ]
}
```