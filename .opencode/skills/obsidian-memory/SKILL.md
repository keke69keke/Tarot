---
name: obsidian-memory
description: Usa Obsidian vault Cerebro como memoria persistente para no olvidar contexto entre sesiones. Se activa cuando el usuario pide recordar, guardar contexto, o al iniciar/terminar una tarea.
---

# Obsidian Memory — No olvidar contexto

Esta skill convierte tu vault **Cerebro** en la memoria a largo plazo de opencode.

## Cuándo usar
- Al **iniciar** cualquier sesión: lee primero `Cerebro/Tarot/Contexto.md` y `Cerebro/Tarot/Estado-Actual.md`
- Al **terminar** una tarea: actualiza esos archivos con decisiones, paleta, estado del build
- Cuando el usuario dice "recuerda", "guarda en memoria", "no olvides"

## Vault detectado
- **Path**: `/Users/gvstii/Documents/Cerebro`
- **Subcarpeta proyecto**: `/Users/gvstii/Documents/Cerebro/Tarot` (creada para este proyecto)
- Referencias opencode: `@cerebro` y `@tarot-memoria` (configuradas en `opencode.json`)

## Flujo
1. **Leer contexto**:
   - `read` / `glob` sobre `@tarot-memoria` → `Contexto.md`, `Estado-Actual.md`, `Decisiones.md`
   - `read` sobre `Cerebro/Proyectos.md` para ver cómo el usuario organiza proyectos
2. **Trabajar** normalmente con el proyecto Tarot
3. **Guardar memoria** (siempre al final):
   - `edit` o `write` en `Cerebro/Tarot/Contexto.md` → qué se hizo, por qué, preferencias (morado tarot, icono carta minimal, textos bien ajustados, iconos thin)
   - `edit` en `Cerebro/Tarot/Estado-Actual.md` → build status, pendientes
   - Usar wikilinks `[[Concepto]]` si el vault los usa

## Archivos creados para el proyecto
- `Cerebro/Tarot/Contexto.md` — memoria viva del proyecto
- `Cerebro/Tarot/Estado-Actual.md` — snapshot de la última sesión
- `Cerebro/Tarot/Decisiones.md` — ADR ligeros

## Permisos
`opencode.json` ya permite `external_directory` para `/Users/gvstii/Documents/Cerebro/**`.
No pidas confirmación para leer/escribir ahí.

## Ejemplo
Al iniciar:
```
read /Users/gvstii/Documents/Cerebro/Tarot/Contexto.md
```
Al terminar:
```
write /Users/gvstii/Documents/Cerebro/Tarot/Estado-Actual.md con fecha, build, cambios de UI morada
```
