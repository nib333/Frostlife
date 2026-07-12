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
sfdk config --push target SailfishOS-5.2.<ver>-aarch64
sfdk build                                               # cross-compiles to ARM, builds the RPM
sfdk deploy --sdk                                        # or deploy to a connected device
```
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

Palette (dark-first mapping of the real Frostbite tokens; `canvas`/`surfaceAlt`/`hairline` are derived, muted + states are lightened for dark, the rest are exact Frostbite values):
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
**MVP (build first, get on device early):** multi-player life totals, commander-damage matrix, a few core counters (poison, commander tax), autosave, keep-screen-awake, reset / starting-life presets (20 / 30 / 40).
**Full parity (later):** remaining counters (energy, experience, storm, monarch, initiative, city's blessing), undo/history UI, dice/coin/high-roll, seating randomizer, cover page, per-game stats.

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

## Current repo status (scaffolded July 2026, pre-device)
- Logic engine `qml/js/gamestate.js` is COMPLETE and TESTED: run `node tests/test_gamestate.js` (51 tests, must stay green). It has zero QML deps — extend logic there, test under node first, then wire to UI.
- All QML written but **never rendered** — compiles-on-paper only. First task on any session with SDK access: `sfdk build`, fix compile/QML errors, then ask Niklas for emulator/device screenshots before touching layout.
- Persistence = JSON blob in dconf via `Nemo.Configuration` (debounced 1s + flush on background). Fine for this state size; don't add SQL.
- UI refresh pattern: QML can't observe plain JS objects, so root exposes `app.rev` (increments on every mutation) and panels bind through it. Keep this pattern; don't fight it with deep bindings.
