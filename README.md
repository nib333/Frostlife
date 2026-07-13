# Frostbite Life Counter

Dark-first, EDH-focused Magic: The Gathering life counter for Sailfish OS.
Target device: 2026 Jolla Phone (aarch64, Sailfish OS 5.2, AMOLED).

Pure-QML Silica app. No backend, no network access — all data stays on your
device. All state local, autosaved.

## Features (implemented, device-verified)
- 2–6 players, explicit row layout; every row except the bottom one flips 180°
  so players across the table read right-side-up
- Tap ±1 life, press-and-hold ±5 (repeating)
- Commander damage matrix per source player, partner slots, life auto-deduction, 21-lethal
- Commander naming: labels use the commander's name, falling back to
  player name / "· A"/"· B" for unnamed partners (`cmdLabel`)
- Poison / energy / experience / commander tax counters
- Custom counters (max 8) — names survive reset, values zeroed
- Custom statuses (max 4) — names survive reset, switched off
- Monarch & initiative (exclusive), city's blessing
- Interactive panel pills with −/+ for commander damage and all counters
- Priority-based panel layout (life > damage > counters > status) with
  compact mode on small panels: aggregate "⚔ max +N" damage pill,
  2-column counter grid, "+N" overflow pills/chips that open the detail page
- Status chips anchored to the panel bottom, with camera-cutout clearance
  on top-row (flipped) panels
- Undo / redo (bounded history) with descriptive log entries
  ("undo: Player 3 takes 1 cmd dmg from Player 1 → 4")
- History page: reverse-chronological action log + undo/redo buttons
  (pulley menu → History)
- Autosave to dconf (debounced + flush on background) — survives crash/reboot
- Screen keep-awake while app is active (`Nemo.KeepAlive`)
- Cover page with live life totals + reset action
- Dead-player detection (life ≤ 0, poison ≥ 10, 21 cmd dmg) with panel overlay

## Prerequisites
1. **Sailfish SDK** — https://sailfishos.org/develop (choose the **Docker** build
   engine; ~15 GB disk). The emulator additionally needs VirtualBox but is optional.
2. During SDK install, add the **aarch64** build target for the latest Sailfish 5.x.
3. On the phone: Settings → Developer tools → enable Developer Mode (+ remote
   connection for deploy over Wi-Fi/USB).

## Build & deploy (sfdk CLI)
```sh
sfdk tools list                                    # find exact target name
sfdk config target=SailfishOS-5.2.0.29-aarch64     # adjust to your target
sfdk build                                         # → RPM in ./RPMS/
sfdk config device=<your-device-name>              # devices set up in the IDE
sfdk deploy --sdk                                  # install + run on device
```
Or open `harbour-frostlife.pro` in the Sailfish IDE and hit Deploy.

## Logic tests (no SDK needed)
The whole game engine is plain JS with zero QML dependencies:
```sh
node tests/test_gamestate.js     # 94 tests: cmd damage, undo/redo log, persistence, rules, custom counters/statuses
```
Any change to `qml/js/gamestate.js` must keep this green.

## Architecture
- `qml/js/gamestate.js` — the entire game engine. Plain serializable objects;
  every mutation via `applyAction()`, which snapshots for undo. See file header.
- `qml/harbour-frostlife.qml` — owns the game object; exposes `app.act()`,
  `app.rev` (bump-on-change; UI binds to it), `app.pal` (dark-first Frostbite
  tokens — a QtObject on the root, deliberately NOT a qmldir singleton),
  undo/redo, autosave, keep-awake.
- `qml/components/PlayerPanel.qml` — one player tile: full-panel life tap
  zones, then name row / clipped pill area / status chip row reserved
  structurally; compact mode + overflow when space runs out.
- `qml/components/CounterPill.qml`, `CounterChip.qml` — interactive −/+ pill
  and display-only chip; `StepperRow.qml` — label/−/value/+ row on the
  detail page.
- `qml/pages/` — main layout (Column of Rows), player detail (counters +
  cmd damage matrix), history (log + undo/redo), new-game dialog.
- `qml/cover/CoverPage.qml` — backgrounded view.

## Known limitations / next steps
- No storm counter, timers, or Scryfall art yet.
- Landscape locked out for now (portrait only).
- Compact-mode and chip-row capacities are estimated from counts/character
  widths (clipping is the backstop) — extreme custom-counter names may trip
  "+N" overflow slightly early or late.
