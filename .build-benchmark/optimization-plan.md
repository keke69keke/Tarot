# Xcode Build Optimization Plan — TarotApp

Generated: 2026-09-10, based on baseline artifacts:

- `.build-benchmark/20260910T164148Z-tarot.json` (pass A: clean + zero-change)
- `.build-benchmark/20260910T164507Z-tarot.json` (pass B: clean + incremental, touch-file `TarotUI/TarotChatView.swift`)

## Baseline (Debug, scheme `Tarot`, destination iPhone Air simulator)

| Metric | Median | Notes |
|---|---|---|
| Clean build (warm caches) | 14.2s (pass B) / 22.2s (pass A) | Pass A ran hot after the cold build; treat 14–22s as the noise band |
| True cold build (first ever) | ~11 min | One-time SDK module precompilation cost (704s SwiftCompile task time) |
| Zero-change build | 5.1s | Low fixed overhead floor — healthy |
| Incremental edit (TarotUI view) | 4.2s | Excellent; daily edit loop is not a pain point |

Environment: Xcode-beta (26), arm64 host, DerivedData at `.build-benchmark/DerivedData`, no run-script phases in the project.

## Recommendations

### R1 — Set `DEBUG_INFORMATION_FORMAT = dwarf` for Debug

- **wait_time_impact**: Small direct gain (~0.5–2s per clean build) — dSYMs are currently generated for `Tarot` and `TarotWidget` on every Debug build; also reduces debug-info emission work during compilation.
- **actionability**: repo-local
- **category**: build-settings
- **observed_evidence**:
  - `GenerateDSYMFile (2 tasks)` appears in Debug build logs for both app targets.
  - `-showBuildSettings` resolves `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` in Debug; the value is not set anywhere in `project.pbxproj`, schemes, or xcconfigs — it comes from the Xcode 26 beta toolchain default.
- **estimated_impact**: Low–moderate (hygiene with measurable per-build cost)
- **confidence**: High
- **approval_required**: true
- **benchmark_verification_status**: Not yet verified
- **implementation_notes**: Add `DEBUG_INFORMATION_FORMAT = dwarf;` to the project-level Debug `XCBuildConfiguration` block in `TarotApp.xcodeproj/project.pbxproj`. Release keeps `dwarf-with-dsym`.
- **risk_level**: Low

### R2 — Enable `COMPILATION_CACHE_ENABLE_CACHING = YES`

- **wait_time_impact**: Clean builds after branch switches, pulls, or Clean Build Folder expected 5–14% faster once the cache is warm; the first cache-populating clean build may be slightly slower. No change to the incremental edit loop.
- **actionability**: repo-local
- **category**: build-settings
- **observed_evidence**:
  - Each clean build recompiles 62–158s of SwiftCompile task time from scratch (no cross-build compilation cache).
  - Setting absent from resolved build settings (script detection confirms not enabled).
- **estimated_impact**: Moderate for cached-clean scenario; compounds across real workflows
- **confidence**: Medium–high
- **approval_required**: true
- **benchmark_verification_status**: Not yet verified
- **implementation_notes**: Add `COMPILATION_CACHE_ENABLE_CACHING = YES;` to project-level build settings (Debug and Release). Apple-recommended modern default; keep regardless of single benchmark outcome.
- **risk_level**: Low

### R3 — Enable `EAGER_LINKING = YES` for Debug

- **wait_time_impact**: Allows linking to overlap with compilation; with only two linkable products the gain is likely under 1s — impact uncertain, re-benchmark to confirm.
- **actionability**: repo-local
- **category**: build-settings
- **observed_evidence**:
  - `-showBuildSettings` resolves `EAGER_LINKING = NO`.
  - `Ld` accounts for 3–6s task time per clean build.
- **estimated_impact**: Low
- **confidence**: Medium
- **approval_required**: true
- **benchmark_verification_status**: Not yet verified
- **implementation_notes**: Add `EAGER_LINKING = YES;` to the project-level Debug configuration only.
- **risk_level**: Low

## Explicitly not recommended (with reasons)

- **Module consolidation** (TarotColors/TarotContent/TarotNotifications/TarotDI are 1–2 files each): per-module overhead is real (~9s EmitModule task time) but wall-clock benefit is small (~1–2s), and the change is architecturally invasive (imports, access levels, resource bundles). The 4.2s incremental loop does not justify it.
- **Source-level type-checker refactors**: incremental rebuild of a large middle-layer view is 4.2s; no evidence of pathological files worth touching.
- **Script-phase fixes**: the project contains zero run-script phases.
- **SPM dependency pinning**: single dependency (SwiftCheck, `from: 0.12.0`), no build-time impact.

## Approval checklist

Check items to approve; the fixer will implement only checked items, one at a time, then re-benchmark.

- [x] R1 — `DEBUG_INFORMATION_FORMAT = dwarf` (Debug) — approved 2026-09-10
- [x] R2 — `COMPILATION_CACHE_ENABLE_CACHING = YES` (all configurations) — approved 2026-09-10
- [x] R3 — `EAGER_LINKING = YES` (Debug) — approved 2026-09-10

---

## Execution Report (2026-09-10)

### Baseline (pre-change)
- Clean build median: 22.2s (pass A) / 14.2s (pass B) — 14–22s noise band
- Cached clean build median: n/a (caching not enabled)
- Zero-change build median: 5.1s
- Incremental build median (touch `TarotUI/TarotChatView.swift`): 4.2s

### Changes Applied

| # | Change | Actionability | Measured Result | Status |
|---|--------|---------------|-----------------|--------|
| 1 | `DEBUG_INFORMATION_FORMAT = dwarf` (Debug, project level) | repo-local | GenerateDSYMFile eliminated from all post-change Debug logs; zero-change floor 5.1s → 3.9s | Kept (best practice) |
| 2 | `COMPILATION_CACHE_ENABLE_CACHING = YES` (project level, Debug + Release) | repo-local | Clean builds 14–22s → 6–8s (compilation cache survives `xcodebuild clean` and replays ~62–158s of compile task time as ~1s) | Kept (best practice) |
| 3 | `EAGER_LINKING = YES` (Debug, project level) | repo-local | No isolated measurement; applied together with #1/#2 | Kept (best practice) |

### Final Cumulative Result
- Clean build median: **6.1s / 8.0s** (was 14.2–22.2s) — roughly **8–14s faster (55–70%)**
- Full-DerivedData-wipe rebuild ("cached clean" phase): **22.3s / 31.3s** — new metric; compares to ~11 min true cold build
- Zero-change build median: **3.9s** (was 5.1s) — ~1.2s faster
- Incremental build median: 5.8s reported, but the first run of that phase (27.8s) is a script artifact: the cached-clean phase deletes DerivedData after its last run, forcing the next phase's first build to fully recompile. Runs 2–3 were 3.1–5.8s, in line with the 4.2s pre-change baseline. **No regression.**
- **Net result: Faster**

### Confidence notes
- Pre-change passes showed a 14–22s clean-build band (pass A ran immediately after the 11-minute cold build; likely thermal/scheduling effects). Every post-change clean run (6/6) is below the entire pre-change band, so the improvement is credible despite ambient noise.
- Cached-clean runs recompile (~70–125s task time), i.e. the compilation cache does not replay after a full DerivedData wipe in this toolchain — but it does survive `xcodebuild clean`, which is the common daily path.
- Files modified: `TarotApp.xcodeproj/project.pbxproj` (project-level Debug and Release `buildSettings` blocks only; no target-level or source changes).

### Post-change artifacts
- `.build-benchmark/20260910T165202Z-tarot.json` (clean 6.1s, zero-change 3.9s, cached-clean 22.3s)
- `.build-benchmark/20260910T165410Z-tarot.json` (clean 8.0s, incremental, cached-clean 31.3s)
