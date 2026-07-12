# Frostbite Life Counter

Dark-first, EDH-focused Magic: The Gathering life counter for Sailfish OS.
Target device: 2026 Jolla Phone (aarch64, Sailfish OS 5.2, AMOLED).

Pure-QML Silica app. No backend, no network. All state local, autosaved.

## Features (MVP, implemented)
- 2–6 players, responsive grid, across-the-table panels flipped 180°
- Tap ±1 life, press-and-hold ±5 (repeating)
- Commander damage matrix per source player, partner slots, life auto-deduction, 21-lethal
- Poison / energy / experience / commander tax counters
- Monarch & initiative (exclusive), city's blessing
- Undo / redo (bounded history), action log
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
node tests/test_gamestate.js     # 51 tests: cmd damage, undo, persistence, rules
```
Any change to `qml/js/gamestate.js` must keep this green.

## Architecture
- `qml/js/gamestate.js` — the entire game engine. Plain serializable objects;
  every mutation via `applyAction()`, which snapshots for undo. See file header.
- `qml/harbour-frostlife.qml` — owns the game object; exposes `app.act()`,
  `app.rev` (bump-on-change; UI binds to it), undo/redo, autosave, keep-awake.
- `qml/components/Palette.qml` — dark-first Frostbite tokens (singleton).
- `qml/components/PlayerPanel.qml` — one player tile (tap zones, chips).
- `qml/pages/` — main grid, player detail (counters + cmd damage), new-game dialog.
- `qml/cover/CoverPage.qml` — backgrounded view.

## Known limitations / next steps
- QML has NOT yet been visually verified — first run on emulator/device pending.
- Odd player counts put the last player full-width at the bottom (no 90° side seats yet).
- No storm counter, dice/coin, seating randomizer, timers, or Scryfall art yet.
- Landscape locked out for now (portrait only).
