# Frostlife

<a href="https://liberapay.com/nib333/donate"><img src="https://img.shields.io/liberapay/receives/nib333.svg?logo=liberapay"></a>

Frostlife — a dark, EDH-focused Magic: The Gathering life counter
for Sailfish OS. Pure-QML Silica app. No backend, no network access — all
data stays on your device. All state local, autosaved.

## Features (implemented, device-verified)
- 2–6 players, explicit row layout; every row except the bottom one flips 180°
  so players across the table read right-side-up
- Around-the-table seating mode (opt-in, 4+ players): ±90° side seats along
  the phone's long edges, wide panel arrangement
- Tap ±1 life, press-and-hold ±5 (repeating), with a transient accumulated
  delta indicator (green gains / red losses)
- Commander damage matrix per source player, partner slots, 21-lethal; entering
  damage also deducts life ("Commander damage reduces life" in Settings, on by
  default)
- Commander naming: labels use the commander's name, falling back to
  player name / "· A"/"· B" for unnamed partners (`cmdLabel`)
- Poison / energy / experience / commander tax counters
- Custom counters (max 8) — names survive reset, values zeroed
- Custom statuses (max 4) — names survive reset, switched off
- Monarch & initiative (exclusive), city's blessing
- Interactive panel pills with −/+ for commander damage and all counters
- Bottom pill strip filled by priority (life → damage → counters) with compact
  mode when the slots run out: aggregate "⚔ max +N" damage pill, "+N" overflow
  pills that open the detail page. The grid is 2 columns in rows mode, 4 in
  around-the-table mode
- Status chips in a fixed-height row directly under the player name, at the
  panel-local top — capped separately, by width, with their own "+N" overflow
  chip; camera-cutout clearance on whichever panel edge sits at the physical top
- Undo / redo (bounded history) with descriptive log entries
  ("undo: Player 3 takes 1 cmd dmg from Player 1 → 4"); reset is undoable —
  one Undo restores the whole pre-reset game
- History page: reverse-chronological action log + undo/redo buttons
  (pulley menu → History)
- Autosave to dconf (debounced + flush on background) — survives crash/reboot
- New game carries player identities seat-for-seat; optional randomized seating
- Per-game stats: End game records the winner; standings by name
  (case-insensitive), recent-games list, clear behind a remorse timer
- Settings: rules toggles, keep-awake gate, true-black AMOLED canvas,
  seating layout
- Tools: roll-for-first-player (long ceremonial reveal), d20/d6/coin flip
  (brief roll flicker, tap to re-roll)
- Screen keep-awake while app is active (`Nemo.KeepAlive`, user-gated)
- Cover page with live life totals + undo and reset cover actions
- Dead-player detection (life ≤ 0, poison ≥ 10, 21 cmd dmg) with panel overlay
  ("Automatic death detection" in Settings, on by default)

## Prerequisites
1. **Sailfish SDK** — https://sailfishos.org/develop (choose the **Docker** build
   engine; ~15 GB disk). The emulator additionally needs VirtualBox but is optional.
2. During SDK install, add the **aarch64** build target for the latest Sailfish 5.x.
3. On the phone: Settings → Developer tools → enable Developer Mode (+ remote
   connection for deploy over Wi-Fi/USB).

## Build & deploy (sfdk CLI)
```sh
sfdk tools list                                    # list installed targets
sfdk config target=SailfishOS-5.1.0.11-aarch64     # this build is made with 5.1.0.11
sfdk build                                         # → RPM in ./RPMS/
sfdk config device=<your-device-name>              # devices set up in the IDE
sfdk deploy --sdk                                  # install + run on device
```
Don't copy the target version verbatim — use whatever `sfdk tools list` prints
on your own machine. Any aarch64 target works; 5.1 RPMs run fine on a 5.2 phone.

`sfdk build` writes the RPM to `./RPMS/` by default. If you have configured an
`output-prefix`, it lands in a target-named subdirectory under that instead —
e.g. `~/RPMS/SailfishOS-5.1.0.11-aarch64/`.

Or open `harbour-frostlife.pro` in the Sailfish IDE and hit Deploy.

## Logic tests (no SDK needed)
The whole game engine is plain JS with zero QML dependencies:
```sh
node tests/test_gamestate.js     # 175 tests: cmd damage, undo/redo, persistence, rules, customs, shuffle, stats, robustness, stress
```
Any change to `qml/js/gamestate.js` must keep this green.

## Architecture
- `qml/js/gamestate.js` — the entire game engine. Plain serializable objects;
  every mutation via `applyAction()`, which snapshots for undo. See file header.
- `qml/harbour-frostlife.qml` — owns the game object; exposes `app.act()`,
  `app.rev` (bump-on-change; UI binds to it), `app.pal` (dark palette
  tokens — a QtObject on the root, deliberately NOT a qmldir singleton),
  undo/redo, autosave, keep-awake.
- `qml/components/PlayerPanel.qml` — one player tile: full-panel life tap
  zones, then name row → status chips → life → bottom pill strip, the strip
  reserved structurally; compact mode + overflow when space runs out.
- `qml/components/CounterPill.qml`, `CounterChip.qml` — interactive −/+ pill
  and display-only chip; `StepperRow.qml` — label/−/value/+ row on the
  detail page.
- `qml/pages/` — main layout (rows or around-the-table), player detail
  (counters + cmd damage matrix), history, settings, tools, stats,
  new-game / end-game dialogs.
- `qml/cover/CoverPage.qml` — backgrounded view.

## Known limitations / next steps
- No storm counter or timers yet.
- Landscape locked out for now (portrait only).
- Compact-mode and chip-row capacities are estimated from counts/character
  widths (clipping is the backstop) — extreme custom-counter names may trip
  "+N" overflow slightly early or late.
