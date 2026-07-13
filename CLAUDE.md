# CLAUDE.md — Frostbite Life Counter

## What this is
Native Sailfish OS life-counter app for Magic: The Gathering, EDH/Commander-focused. Solo project. Shares the Frostbite brand but is a **completely separate, self-contained codebase**: no backend, no auth, no database, no network except optional Scryfall card art. All state is local. This simplicity is the point — it removes most of what makes apps hard.

(`harbour-frostlife` is a placeholder name — rename freely, but keep the `harbour-` prefix if you ever want store submission.)

## Target device
- 2026 Jolla Phone (DIT model), Sailfish OS 5.2.
- SoC: MediaTek Dimensity 7100 → **aarch64** (64-bit ARM). Build target is `aarch64`, NOT the old `armv7hl`.
- Display: 6.36" FullHD+ AMOLED, 20:9, ~390 ppi. Design for this tall aspect ratio.
- AMOLED matters here: the counter runs screen-on for a whole game, so **dark-first design** (true-black backgrounds) is a genuine battery win, not just aesthetics.

## Stack
- **QML + Sailfish Silica** for all UI. Pure-QML app (`CONFIG += sailfishapp_qml`); the C++ `main()` is the stock `SailfishApp::main()` and stays minimal.
- Logic in JavaScript, in QML or separate `.js` modules.
- Packaged as **RPM** by the Sailfish SDK build engine.
- Do not carry over React/Next mental models — QML is declarative with property bindings, and its imperative escape hatches differ.

## ⚠️ Hard constraint: you cannot see the UI
You (the agent) **cannot see rendered QML**. Code that compiles can still be visually broken — misaligned, unreadable, wrong rotation, bad spacing.
- After ANY change affecting layout or appearance, **stop and ask Niklas for a screenshot or description** before continuing. Never assume a UI change worked.
- Never chain multiple UI changes without a visual check in between.
- Logic changes (damage math, counters, persistence) can proceed normally — but cover them with tests.

## Build & deploy (CLI)
The SDK ships `sfdk`. Typical loop:
```
sfdk tools list                                          # find the exact aarch64 target name
sfdk config --global --push target SailfishOS-5.1.0.11-aarch64   # installed tooling (5.1 RPMs run fine on the 5.2 phone)
sfdk build                                               # cross-compiles to ARM, builds the RPM
sfdk deploy --sdk                                        # or deploy to a connected device
```
- Set the target at **global** scope — session scope doesn't survive across shell invocations.
- RPMs land in `~/RPMS/SailfishOS-5.1.0.11-aarch64/`. No `sfdk device` is configured; Niklas deploys.
- Device SSH (`defaultuser@192.168.2.15`) is password-only — the agent cannot pull `journalctl` itself; ask Niklas for logs (`ssh` in, run `sailfish-qml harbour-frostlife` to see QML errors live).
- Read compiler/QML errors from `sfdk build` and fix in a loop — **this half of the feedback cycle IS available to you.**
- The SDK **emulator is x86 (i486) in VirtualBox** and won't match aarch64 exactly. Use it for logic/layout sanity only; **final legibility and battery checks happen on the real phone** (manual — Niklas does these).
- Docker build engine pulls from Jolla repos — if run in a sandbox, those domains must be allowlisted, or run the SDK outside the sandbox.

## Project layout
```
harbour-frostlife/
├── harbour-frostlife.pro
├── rpm/harbour-frostlife.spec
├── qml/
│   ├── harbour-frostlife.qml     # ApplicationWindow
│   ├── pages/                    # MainPage, per-player panels, settings
│   ├── cover/CoverPage.qml       # life totals shown when backgrounded
│   └── js/                       # game logic modules (damage model, history)
└── src/harbour-frostlife.cpp     # stock SailfishApp::main()
```

## Architecture — the parts that need care
1. **Commander-damage model = N×N matrix.** Each player tracks damage received from every other player's commander, split per partner. Build and test this data model *first*; the swipe-to-view UI is trivial once the model is right.
2. **Undo/redo + action history.** Keep a clean action log / state stack from the start — do not bolt it on later. Every mutation (life ±, counter ±, damage) is a history entry.
3. **Autosave / crash protection.** Persist full game state so a crash or reboot never wipes a game. Simplest Harbour-safe route: serialize state to JSON in the app's data dir on every mutation (debounced), reload on launch.
4. **Multi-player layouts (2–6).** Rotated/inverted panels so players around a table read right-side-up. Use QML rotation transforms; arrange responsively for the 20:9 screen.

## Design language (dark-first, Sailfish-native, Frostbite accent)
**Decision: dark theme, not the light Frostbite marketplace look.** Reasons: (1) the counter is screen-on for the whole game via `preventBlanking`, and on AMOLED a dark base keeps most pixels physically off — a light background would light nearly every pixel at brightness for an hour; (2) Silica is dark by default, so a dark app feels native; (3) high-contrast pale-on-dark reads better across a table and in dim rooms. The brand is carried through the **frost-blue accent and calm character**, not a light background. (If ever flipped to light, the original tokens map straight across.)

Palette (dark-first mapping of the real Frostbite tokens; `canvas`/`surfaceAlt`/`hairline` are derived, muted + states are lightened for dark, the rest are exact Frostbite values). It lives as a QtObject on the app root — reference it as `app.pal.*` (NOT a qmldir singleton; see Device lessons):
```qml
readonly property color canvas:      "#0e161d"  // deep base / gutters (use "#000000" for max AMOLED)
readonly property color surface:     "#1c2832"  // player panels / cards  = Frostbite `ink`
readonly property color surfaceAlt:  "#26333e"  // raised fills / dividers
readonly property color primaryText: "#f4f7f9"  // = Frostbite `onInk`
readonly property color mutedText:   "#9aa8b3"  // secondary text
readonly property color hairline:    "#2b3a45"  // rules on dark
readonly property color frostBlue:   "#7dbfe5"  // accent / active player = Frostbite `frostBlue`
readonly property color success:     "#4ade80"
readonly property color error:       "#f87171"
readonly property color warning:     "#fbbf24"
```
- `ink #1c2832` is dark but not true black — use it for **panels**, keep `canvas` as the deepest layer so "off" areas actually save power.
- Large legible numbers, hairline rules, generous spacing, calm and premium. Legibility beats decoration.
- Prefer Silica `Theme` sizing/spacing tokens over hardcoded pixels where practical.

## Feature scope
**Implemented and device-verified:** multi-player life totals (2–6, explicit row layout, flip rule = every row except the bottom row flips 180°); commander-damage matrix with partner slots and `cmdLabel` naming (commander name, falling back to player name / "· A"/"· B" for unnamed partners); counters poison/energy/experience/cmd tax; custom counters (max 8; names survive reset, values zeroed); custom statuses (max 4; names survive reset, switched off); monarch/initiative (exclusive) + city's blessing; interactive panel pills with ± for damage and counters; priority-based panel layout (life > damage > counters > status) with compact mode — aggregate "⚔ max +N" damage pill, 2-column counter grid, "+N" overflow pills/chips that open the detail page; bottom-anchored status chips with camera-cutout clearance on top-row panels; History page (reverse-chronological log, undo/redo buttons, descriptive "undo: <action>" entries); autosave; keep-screen-awake; reset / starting-life presets; cover page.
**Still to build:** storm counter, dice/coin/high-roll, seating randomizer, per-game stats, optional Scryfall card art, 90° side seats, landscape.

## Keep-awake
Use `Nemo.KeepAlive` → `DisplayBlanking { preventBlanking: true }` during an active game (Harbour-allowed). Only prevent blanking while a game is active; release it otherwise.

## Harbour rules (only if publishing to the store)
- App name / binary use the `harbour-` prefix.
- Only whitelisted APIs are allowed (`Nemo.KeepAlive` is fine). Check any new import against the Harbour FAQ before relying on it.
- Not needed for personal sideloading via Developer Mode — only for store submission.

## Testing discipline (mirror Frostbite)
- The logic layer (damage math, life arithmetic, counter edge cases, autosave round-trip) must have tests. Treat it like the landed-cost harness: correctness first, then wire to UI.
- Gate-review before commits. Niklas reviews; the agent does not self-approve UI it cannot see.

## References (Silica is thin in training data — lean on these)
- Sailfish docs: https://docs.sailfishos.org
- Silica component reference (in the SDK: Help → Sailfish Silica Reference)
- CounterSpell (open-source EDH counter) for feature/layout ideas — likely not QML, so port concepts, not code.

## Current repo status (July 2026, on-device and iterating)
- Logic engine `qml/js/gamestate.js` is COMPLETE and TESTED: run `node tests/test_gamestate.js` (**94 tests**, must stay green). It has zero QML deps — extend logic there, test under node first, then wire to UI.
- All QML has been **deployed and visually verified on the real phone** through several screenshot rounds (layout, flip rules, compact mode, History page). The workflow stands: after any UI change, `sfdk build`, then ask Niklas for device screenshots before iterating further.
- Persistence = JSON blob in dconf via `Nemo.Configuration` (debounced 1s + flush on background). Fine for this state size; don't add SQL. Undo snapshots carry a `text` label for descriptive undo/redo — added without a schema bump; old saves still load.
- UI refresh pattern: QML can't observe plain JS objects, so root exposes `app.rev` (increments on every mutation) and panels bind through it. Keep this pattern; don't fight it with deep bindings.

## Device lessons (hard-won on the real phone — do not relearn)
- **qmldir-registered QML singletons compile fine but failed silently at runtime** under `sailfish-qml`: every `Palette.*` reference logged "Unable to assign [undefined] to QColor" and Rectangles fell back to default white. The palette now lives as a plain QtObject on the app root (`app.pal.*`), resolved by the same id lookup as `app.rev`/`app.act`. Don't reintroduce qmldir singletons.
- **Every displayed value must bind through `app.rev` explicitly.** Capturing a JS object into a property without an `app.rev` dependency (e.g. `readonly property var cc: pl.customCounters[index]`) evaluates once and renders stale forever. Bind by index through `app.rev` in the expression itself.
- **Loader + `Binding { target: item }` + callbacks assigned in `Component.onCompleted` broke on device** (values never refreshed). Use plain file components (StepperRow, CounterPill) with ordinary property bindings and per-row action objects instead.
- **QML `\u` escapes are exactly 4 hex digits.** `"Ὗ2"` parses as U+1F5F + literal "2" and renders garbage. Astral-plane characters need surrogate pairs — but prefer BMP glyphs (♛ ⚔ ♜ ☠ ⚡); device emoji coverage is uncertain.
- **QML `Grid` sizes each column to its widest child** — a full-width child pushes the other column off-screen. Lay out mixed-width rows explicitly (Column of Rows), as MainPage does.
- **Bindings through inline QtObject sub-properties proved unreliable for change delivery on device** (`pal.canvas` updates never reached long-lived pages) — switchable values belong as flat root-window properties written imperatively (the `app.rev` pattern; see `app.canvasColor`).
- **Never size a container from its own rendered content when that content depends on the size** (binding loop). Compact/overflow decisions in PlayerPanel are computed from pill *counts* and theme constants against structurally reserved space, with `clip: true` as the backstop.
- Hardware: the front-camera cutout sits at the physical top — top-row (flipped) panels need extra clearance for anything anchored to their panel-bottom edge (`PlayerPanel.topRow`).
