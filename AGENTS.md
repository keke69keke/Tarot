# AGENTS — Tarot

> Este repo usa Obsidian como memoria persistente. No olvides contexto.

## Memoria
- **Vault**: `/Users/gvstii/Documents/Cerebro`
- **Memoria proyecto**: `/Users/gvstii/Documents/Cerebro/Tarot/Contexto.md` (leer SIEMPRE al iniciar), `Estado-Actual.md`, `Decisiones.md`
- **References opencode**: `@cerebro` y `@tarot-memoria` ya configuradas en `opencode.json`
- **Skill**: `.opencode/skills/obsidian-memory/SKILL.md` — activa cuando te piden recordar/guardar.

## Flujo obligatorio
1. Al iniciar: `read @tarot-memoria/Contexto.md`
2. Al terminar tarea: `write` actualización en `Cerebro/Tarot/Estado-Actual.md` + `Contexto.md` si hay decisión nueva.
3. Usar `external_directory` ya permitido para `~/Documents/Cerebro/**`.

## Contexto actual (2026-08-27)
- App Tarot 100k MXN, **morado lujo minimal limpio** (no joya), icono carta tarot minimal lavanda, textos bien ajustados serif tracking, iconos thin.
- Paleta: fondo `#0F0A22`, acento lavanda `#9984FF`, marcos hairline 0.75, `luxuryGlass`.
- Build OK (iPhone 17), tests 29/29.
