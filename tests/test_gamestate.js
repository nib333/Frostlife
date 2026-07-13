/* Node test harness for gamestate.js — run: node tests/test_gamestate.js */
"use strict";
const G = require("../qml/js/gamestate.js");

let passed = 0, failed = 0;
function ok(cond, name) {
    if (cond) { passed++; console.log("  ✓ " + name); }
    else { failed++; console.error("  ✗ FAIL " + name); }
}
function section(s) { console.log("\n" + s); }

/* ---- construction ---- */
section("construction");
let g = G.createGame(4, 40);
ok(g.players.length === 4, "4 players created");
ok(g.players.every(p => p.life === 40), "all start at 40 life");
ok(g.players[2].cmdDamage.length === 4, "cmdDamage matrix is N wide");
ok(g.players[2].cmdDamage[1].length === 2, "each source has 2 slots (partner)");
ok(G.createGame(1, 20).players.length === 2, "player count clamps to min 2");
ok(G.createGame(9, 20).players.length === 6, "player count clamps to max 6");

/* ---- life ---- */
section("life");
G.applyAction(g, { type: "life", player: 0, delta: -5 });
ok(g.players[0].life === 35, "life -5 → 35");
G.applyAction(g, { type: "life", player: 0, delta: +2 });
ok(g.players[0].life === 37, "life +2 → 37");
G.applyAction(g, { type: "setLife", player: 0, value: 40 });
ok(g.players[0].life === 40, "setLife 40");

/* ---- commander damage ---- */
section("commander damage");
g = G.createGame(4, 40);
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 0, delta: 7 });
ok(g.players[0].cmdDamage[2][0] === 7, "7 cmd dmg recorded from player 2");
ok(g.players[0].life === 33, "cmd dmg also deducts life (rules-correct)");
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 0, delta: -3 });
ok(g.players[0].cmdDamage[2][0] === 4, "correction: -3 → 4");
ok(g.players[0].life === 36, "life refunded on correction");
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 0, delta: -10 });
ok(g.players[0].cmdDamage[2][0] === 0, "cmd dmg clamps at 0");
ok(g.players[0].life === 40, "life refund clamps to actually-applied amount");

// partner slot independent
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 1, delta: 5 });
ok(g.players[0].cmdDamage[2][1] === 5 && g.players[0].cmdDamage[2][0] === 0,
   "partner slot tracked independently");

// lethal at 21 from a single commander
g = G.createGame(3, 40);
G.applyAction(g, { type: "cmdDamage", player: 1, source: 0, slot: 0, delta: 21 });
ok(g.players[1].dead === true, "21 cmd dmg from one commander = dead");
g = G.createGame(3, 40);
G.applyAction(g, { type: "cmdDamage", player: 1, source: 0, slot: 0, delta: 11 });
G.applyAction(g, { type: "cmdDamage", player: 1, source: 2, slot: 0, delta: 10 });
ok(g.players[1].dead === false, "11+10 from DIFFERENT commanders ≠ dead");
ok(g.players[1].life === 19, "but life still reduced by 21 total");

// setting off
g = G.createGame(2, 40);
g.settings.cmdDamageAffectsLife = false;
G.applyAction(g, { type: "cmdDamage", player: 0, source: 1, slot: 0, delta: 6 });
ok(g.players[0].life === 40 && g.players[0].cmdDamage[1][0] === 6,
   "cmdDamageAffectsLife=false leaves life untouched");

/* ---- counters & death ---- */
section("counters & death");
g = G.createGame(2, 40);
G.applyAction(g, { type: "counter", player: 0, counter: "poison", delta: 10 });
ok(g.players[0].dead === true, "10 poison = dead");
G.applyAction(g, { type: "counter", player: 0, counter: "poison", delta: -10 });
ok(g.players[0].dead === false, "death recomputed when poison removed");
G.applyAction(g, { type: "counter", player: 0, counter: "energy", delta: -5 });
ok(g.players[0].counters.energy === 0, "counters clamp at 0");
G.applyAction(g, { type: "life", player: 1, delta: -40 });
ok(g.players[1].dead === true, "life 0 = dead");
let threw = false;
try { G.applyAction(g, { type: "counter", player: 0, counter: "nope", delta: 1 }); }
catch (e) { threw = true; }
ok(threw, "unknown counter throws");

/* ---- monarch / initiative exclusivity ---- */
section("monarch & initiative");
g = G.createGame(4, 40);
G.applyAction(g, { type: "monarch", player: 1 });
G.applyAction(g, { type: "monarch", player: 3 });
ok(!g.players[1].monarch && g.players[3].monarch, "monarch moves, is exclusive");
G.applyAction(g, { type: "monarch", player: 3 });
ok(!g.players[3].monarch, "toggling same player clears monarch");
G.applyAction(g, { type: "initiative", player: 0 });
G.applyAction(g, { type: "initiative", player: 2 });
ok(!g.players[0].initiative && g.players[2].initiative, "initiative exclusive");

/* ---- undo / redo ---- */
section("undo / redo");
g = G.createGame(2, 20);
G.applyAction(g, { type: "life", player: 0, delta: -3 });
G.applyAction(g, { type: "cmdDamage", player: 0, source: 1, slot: 0, delta: 4 });
ok(g.players[0].life === 13, "state before undo: 20-3-4 = 13");
G.undo(g);
ok(g.players[0].life === 17 && g.players[0].cmdDamage[1][0] === 0, "undo reverts cmd dmg + life together");
G.undo(g);
ok(g.players[0].life === 20, "second undo reverts life change");
ok(!G.canUndo(g), "undo stack empty at game start");
G.redo(g);
ok(g.players[0].life === 17, "redo reapplies");
G.redo(g);
ok(g.players[0].life === 13 && g.players[0].cmdDamage[1][0] === 4, "redo to latest");
ok(!G.canRedo(g), "redo stack exhausted");
G.undo(g);
G.applyAction(g, { type: "life", player: 1, delta: 1 });
ok(!G.canRedo(g), "new action clears redo stack");

// bounded history
g = G.createGame(2, 20);
for (let i = 0; i < G.MAX_UNDO + 50; i++)
    G.applyAction(g, { type: "life", player: 0, delta: -1 });
ok(g.history.length === G.MAX_UNDO, "undo stack bounded at MAX_UNDO");

/* ---- unknown action rollback ---- */
section("error handling");
g = G.createGame(2, 20);
const depth = g.history.length;
threw = false;
try { G.applyAction(g, { type: "bogus" }); } catch (e) { threw = true; }
ok(threw && g.history.length === depth, "unknown action throws and leaves no snapshot");

/* ---- serialization ---- */
section("serialization");
g = G.createGame(4, 40);
G.applyAction(g, { type: "rename", player: 0, name: "Niklas" });
G.applyAction(g, { type: "life", player: 0, delta: -7 });
G.applyAction(g, { type: "cmdDamage", player: 1, source: 0, slot: 1, delta: 9 });
G.applyAction(g, { type: "monarch", player: 2 });
const json = G.serialize(g);
const g2 = G.deserialize(json);
ok(g2.players[0].name === "Niklas", "round-trip: name");
ok(g2.players[0].life === 33, "round-trip: life");
ok(g2.players[1].cmdDamage[0][1] === 9, "round-trip: cmd dmg partner slot");
ok(g2.players[2].monarch === true, "round-trip: monarch");
// settings round-trip (SettingsPage relies on this)
g = G.createGame(2, 40);
g.settings.cmdDamageAffectsLife = false;
g.settings.autoDeath = false;
let gS = G.deserialize(G.serialize(g));
ok(gS.settings.cmdDamageAffectsLife === false, "round-trip: cmdDamageAffectsLife");
ok(gS.settings.autoDeath === false, "round-trip: autoDeath");
ok(G.deserialize(G.serialize(G.createGame(2, 40))).settings.cmdDamageAffectsLife === true,
   "round-trip: settings defaults preserved");
G.undo(g2);
ok(g2.players[2].monarch === false, "undo works after deserialize (history survives)");
threw = false;
try { G.deserialize('{"schema":99,"players":[{}]}'); } catch (e) { threw = true; }
ok(threw, "wrong schema version rejected");

/* ---- reset ---- */
section("reset");
g = G.createGame(3, 40);
G.applyAction(g, { type: "rename", player: 1, name: "Aino" });
G.applyAction(g, { type: "partners", player: 1, value: true });
G.applyAction(g, { type: "life", player: 1, delta: -12 });
let fresh = G.resetGame(g);
ok(fresh.players[1].life === 40, "reset restores life");
ok(fresh.players[1].name === "Aino", "reset keeps names");
ok(fresh.players[1].partners === true, "reset keeps partner setting");
ok(fresh.history.length === 0, "reset clears history");
fresh = G.resetGame(g, 20);
ok(fresh.players[0].life === 20, "reset can change starting life");

/* ---- rename edge ---- */
g = G.createGame(2, 20);
G.applyAction(g, { type: "rename", player: 0, name: "" });
ok(g.players[0].name === "Player 1", "empty rename falls back to default");
G.applyAction(g, { type: "rename", player: 0, name: "x".repeat(60) });
ok(g.players[0].name.length === 24, "rename capped at 24 chars");


/* ---- commander naming ---- */
section("commander naming");
g = G.createGame(3, 40);
ok(G.commanderLabel(g.players[1], 0) === "Player 2", "unnamed single commander → player name");
G.applyAction(g, { type: "partners", player: 1, value: true });
ok(G.commanderLabel(g.players[1], 0) === "Player 2 \u00b7 A", "unnamed partner slot 0 → · A");
ok(G.commanderLabel(g.players[1], 1) === "Player 2 \u00b7 B", "unnamed partner slot 1 → · B");
G.applyAction(g, { type: "nameCommander", player: 1, slot: 0, name: "Thrasios" });
G.applyAction(g, { type: "nameCommander", player: 1, slot: 1, name: "Tymna" });
ok(G.commanderLabel(g.players[1], 0) === "Thrasios", "named slot 0 → name");
ok(G.commanderLabel(g.players[1], 1) === "Tymna", "named slot 1 → name");
G.applyAction(g, { type: "nameCommander", player: 1, slot: 0, name: "" });
ok(G.commanderLabel(g.players[1], 0) === "Player 2 \u00b7 A", "cleared name falls back");
G.applyAction(g, { type: "nameCommander", player: 1, slot: 0, name: "x".repeat(60) });
ok(g.players[1].commanderNames[0].length === 24, "commander name capped at 24");
// survives reset + serialization
G.applyAction(g, { type: "nameCommander", player: 1, slot: 0, name: "Thrasios" });
let fresh2 = G.resetGame(g);
ok(fresh2.players[1].commanderNames[0] === "Thrasios", "reset preserves commander names");
const g3 = G.deserialize(G.serialize(g));
ok(g3.players[1].commanderNames[1] === "Tymna", "round-trip: commander names");
// undo covers naming
G.undo(g);
ok(g.players[1].commanderNames[0] === "x".repeat(24), "undo reverts to previous commander name");


/* ---- phantom snapshot regression ---- */
section("phantom snapshot regression");
g = G.createGame(2, 40);
G.applyAction(g, { type: "counter", player: 0, counter: "poison", delta: 3 });
let depth2 = g.history.length;
threw = false;
try { G.applyAction(g, { type: "counter", player: 0, counter: "bogus", delta: 1 }); }
catch (e) { threw = true; }
ok(threw && g.history.length === depth2, "failed counter action leaves no phantom snapshot");
G.undo(g);
ok(g.players[0].counters.poison === 0, "undo after failed action reverts the RIGHT action");


/* ---- custom counters ---- */
section("custom counters");
g = G.createGame(2, 40);
G.applyAction(g, { type: "addCustomCounter", player: 0, name: "Charge" });
ok(g.players[0].customCounters.length === 1 && g.players[0].customCounters[0].name === "Charge",
   "add custom counter");
G.applyAction(g, { type: "customCounter", player: 0, index: 0, delta: 3 });
ok(g.players[0].customCounters[0].value === 3, "custom counter +3");
G.applyAction(g, { type: "customCounter", player: 0, index: 0, delta: -5 });
ok(g.players[0].customCounters[0].value === 0, "custom counter clamps at 0");
G.applyAction(g, { type: "addCustomCounter", player: 0, name: "  Rad  " });
ok(g.players[0].customCounters[1].name === "Rad", "name trimmed");
G.applyAction(g, { type: "addCustomCounter", player: 0, name: "x".repeat(40) });
ok(g.players[0].customCounters[2].name.length === 16, "name capped at 16");
threw = false; depth2 = g.history.length;
try { G.applyAction(g, { type: "addCustomCounter", player: 0, name: "   " }); }
catch (e) { threw = true; }
ok(threw && g.history.length === depth2, "empty name rejected, no phantom snapshot");
threw = false;
try { G.applyAction(g, { type: "customCounter", player: 0, index: 9, delta: 1 }); }
catch (e) { threw = true; }
ok(threw, "bad index rejected");
// cap at 8
g = G.createGame(2, 40);
for (let i = 0; i < 8; i++)
    G.applyAction(g, { type: "addCustomCounter", player: 0, name: "c" + i });
threw = false;
try { G.applyAction(g, { type: "addCustomCounter", player: 0, name: "nine" }); }
catch (e) { threw = true; }
ok(threw && g.players[0].customCounters.length === 8, "capped at 8 custom counters");
// remove
G.applyAction(g, { type: "removeCustomCounter", player: 0, index: 0 });
ok(g.players[0].customCounters.length === 7 && g.players[0].customCounters[0].name === "c1",
   "remove shifts the list");
G.undo(g);
ok(g.players[0].customCounters.length === 8 && g.players[0].customCounters[0].name === "c0",
   "undo restores removed counter");
// reset keeps names, zeroes values; serialization round-trips
g = G.createGame(2, 40);
G.applyAction(g, { type: "addCustomCounter", player: 0, name: "Loyalty" });
G.applyAction(g, { type: "customCounter", player: 0, index: 0, delta: 4 });
fresh = G.resetGame(g);
ok(fresh.players[0].customCounters[0].name === "Loyalty" && fresh.players[0].customCounters[0].value === 0,
   "reset keeps custom counter names, zeroes values");
ok(G.deserialize(G.serialize(g)).players[0].customCounters[0].value === 4, "round-trip: custom counters");


/* ---- custom statuses ---- */
section("custom statuses");
g = G.createGame(2, 40);
G.applyAction(g, { type: "addCustomStatus", player: 0, name: "Ring-bearer" });
ok(g.players[0].customStatuses[0].name === "Ring-bearer" && g.players[0].customStatuses[0].on === false,
   "add status, off by default");
G.applyAction(g, { type: "customStatus", player: 0, index: 0 });
ok(g.players[0].customStatuses[0].on === true, "toggle on");
G.applyAction(g, { type: "customStatus", player: 0, index: 0 });
ok(g.players[0].customStatuses[0].on === false, "toggle off");
threw = false; depth2 = g.history.length;
try { G.applyAction(g, { type: "addCustomStatus", player: 0, name: " " }); }
catch (e) { threw = true; }
ok(threw && g.history.length === depth2, "empty status name rejected, no phantom snapshot");
for (let i = 0; i < 3; i++)
    G.applyAction(g, { type: "addCustomStatus", player: 0, name: "s" + i });
threw = false;
try { G.applyAction(g, { type: "addCustomStatus", player: 0, name: "five" }); }
catch (e) { threw = true; }
ok(threw && g.players[0].customStatuses.length === 4, "capped at 4 custom statuses");
G.applyAction(g, { type: "removeCustomStatus", player: 0, index: 0 });
ok(g.players[0].customStatuses.length === 3 && g.players[0].customStatuses[0].name === "s0",
   "remove shifts list");
G.undo(g);
ok(g.players[0].customStatuses.length === 4, "undo restores removed status");
g = G.createGame(2, 40);
G.applyAction(g, { type: "addCustomStatus", player: 0, name: "Suspected" });
G.applyAction(g, { type: "customStatus", player: 0, index: 0 });
fresh = G.resetGame(g);
ok(fresh.players[0].customStatuses[0].name === "Suspected" && fresh.players[0].customStatuses[0].on === false,
   "reset keeps status names, switches off");
ok(G.deserialize(G.serialize(g)).players[0].customStatuses[0].on === true, "round-trip: custom statuses");

/* ---- descriptive undo/redo log ---- */
section("descriptive undo/redo log");
g = G.createGame(3, 40);
G.applyAction(g, { type: "cmdDamage", player: 2, source: 0, slot: 0, delta: 1 });
const dmgText = g.log[g.log.length - 1].text;
let logLen = g.log.length;
G.undo(g);
ok(g.log[g.log.length - 1].text === "undo: " + dmgText, "undo names the undone action");
ok(g.log.length === logLen + 1, "log is append-only: undone entry stays");
G.redo(g);
ok(g.log[g.log.length - 1].text === "redo: " + dmgText, "redo names the redone action");
G.undo(g);
ok(g.log[g.log.length - 1].text === "undo: " + dmgText, "undo after redo names it again");

g = G.createGame(2, 40);
G.applyAction(g, { type: "life", player: 0, delta: -3 });
G.applyAction(g, { type: "life", player: 1, delta: -7 });
G.undo(g);
ok(g.log[g.log.length - 1].text.indexOf("undo: " + g.players[1].name) === 0,
   "undo picks the LAST action's text");
G.undo(g);
ok(g.log[g.log.length - 1].text.indexOf("undo: " + g.players[0].name) === 0,
   "second undo picks the previous action's text");

g = G.createGame(2, 40);
G.applyAction(g, { type: "blessing", player: 0, value: true });
G.undo(g);
ok(g.log[g.log.length - 1].text === "undo: blessing",
   "non-logging action falls back to its type");

g = G.createGame(2, 40);
G.applyAction(g, { type: "life", player: 0, delta: -1 });
g = G.deserialize(G.serialize(g));
G.undo(g);
ok(g.log[g.log.length - 1].text.indexOf("undo: " + g.players[0].name) === 0,
   "descriptive undo survives serialize round-trip");

g = G.createGame(2, 40);
G.applyAction(g, { type: "life", player: 0, delta: -1 });
delete g.history[g.history.length - 1].text; // old save: snapshot without text
G.undo(g);
ok(g.log[g.log.length - 1].text === "undo", "old-format snapshot logs plain undo");
ok(g.players[0].life === 40, "old-format snapshot still restores state");

/* ---- autoDeath toggle semantics ----
 * Retroactive by design: ON recomputes every player immediately; OFF
 * clears all dead flags, because with detection off nothing else can
 * ever clear a stale flag (refreshDeath early-returns) and there is no
 * manual revive control. */
section("autoDeath toggle semantics");
g = G.createGame(2, 40);
G.applyAction(g, { type: "life", player: 0, delta: -45 });
ok(g.players[0].dead === true, "sanity: dead at life < 0");
G.setAutoDeath(g, false);
ok(g.settings.autoDeath === false, "toggle OFF stored");
ok(g.players[0].dead === false, "OFF clears dead flags (manual mode marks nobody)");
G.applyAction(g, { type: "life", player: 0, delta: -1 });
ok(g.players[0].dead === false, "no re-marking while off");
G.setAutoDeath(g, true);
ok(g.settings.autoDeath === true, "toggle ON stored");
ok(g.players[0].dead === true, "ON recomputes immediately (life still < 0)");

g = G.createGame(3, 40);
g.settings.autoDeath = false;
G.applyAction(g, { type: "counter", player: 1, counter: "poison", delta: 10 });
G.applyAction(g, { type: "cmdDamage", player: 2, source: 0, slot: 0, delta: 21 });
ok(g.players[1].dead === false && g.players[2].dead === false,
   "poison 10 / 21 cmd dmg not marked while off");
G.setAutoDeath(g, true);
ok(g.players[1].dead === true, "ON recompute catches poison deaths");
ok(g.players[2].dead === true, "ON recompute catches 21-cmd-dmg deaths");
ok(g.players[0].dead === false, "ON recompute leaves healthy players alive");

/* ---- newGameFrom (identity carryover) ---- */
section("newGameFrom");
g = G.createGame(3, 40);
G.applyAction(g, { type: "rename", player: 0, name: "Niklas" });
G.applyAction(g, { type: "partners", player: 1, value: true });
G.applyAction(g, { type: "nameCommander", player: 1, slot: 1, name: "Tymna" });
G.applyAction(g, { type: "addCustomCounter", player: 0, name: "Rad" });
G.applyAction(g, { type: "customCounter", player: 0, index: 0, delta: 5 });
G.applyAction(g, { type: "addCustomStatus", player: 2, name: "Suspected" });
G.applyAction(g, { type: "customStatus", player: 2, index: 0 });
g.settings.cmdDamageAffectsLife = false;
G.applyAction(g, { type: "life", player: 0, delta: -10 });
let ng = G.newGameFrom(g, 4, 20);
ok(ng.players.length === 4 && ng.startingLife === 20, "count and life applied");
ok(ng.players[0].name === "Niklas", "name carries seat-for-seat");
ok(ng.players[0].life === 20, "life is fresh, not carried");
ok(ng.players[1].partners === true && ng.players[1].commanderNames[1] === "Tymna",
   "partners + commander names follow");
ok(ng.players[0].customCounters[0].name === "Rad" && ng.players[0].customCounters[0].value === 0,
   "custom counter names carry, values zeroed");
ok(ng.players[2].customStatuses[0].name === "Suspected" && ng.players[2].customStatuses[0].on === false,
   "custom status names carry, switched off");
ok(ng.players[3].name === "Player 4", "new extra seat gets defaults");
ok(ng.settings.cmdDamageAffectsLife === false, "settings carry over");
ok(ng.history.length === 0 && ng.log.length === 0, "history and log are fresh");
ok(G.newGameFrom(g, 2, 40).players.length === 2, "shrinking drops extra seats");

/* ---- shuffleSeats ---- */
section("shuffleSeats");
// rand = () => 0 gives the known permutation [1,2,3,0] (newSeat -> oldSeat)
g = G.createGame(4, 40);
G.applyAction(g, { type: "rename", player: 0, name: "A" });
G.applyAction(g, { type: "rename", player: 1, name: "B" });
G.applyAction(g, { type: "rename", player: 2, name: "C" });
G.applyAction(g, { type: "rename", player: 3, name: "D" });
G.applyAction(g, { type: "partners", player: 2, value: true });
G.applyAction(g, { type: "nameCommander", player: 2, slot: 0, name: "Thrasios" });
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 0, delta: 7 });
G.applyAction(g, { type: "cmdDamage", player: 0, source: 2, slot: 1, delta: 3 });
G.shuffleSeats(g, function () { return 0; });
ok(g.players.map(p => p.name).join("") === "BCDA", "deterministic permutation [1,2,3,0]");
ok(g.players.every((p, i) => p.index === i), "player.index matches new seat");
ok(g.players[1].partners === true && g.players[1].commanderNames[0] === "Thrasios",
   "partners + commander names moved with their player");
// old A (seat 0) is now seat 3; old source C (seat 2) is now seat 1
ok(g.players[3].name === "A" && g.players[3].cmdDamage[1][0] === 7,
   "cmd dmg reindexed: damage follows the source's new seat");
ok(g.players[3].cmdDamage[1][1] === 3, "partner slot follows too");
ok(g.players[3].life === 40 - 10, "shuffled player keeps their life");
ok(g.log[g.log.length - 1].text === "Seating randomized", "shuffle is logged");

// rand = () => 0.9999 swaps nothing: identity permutation
g = G.createGame(3, 40);
G.applyAction(g, { type: "rename", player: 0, name: "X" });
G.shuffleSeats(g, function () { return 0.9999; });
ok(g.players.map(p => p.name).join(",") === "X,Player 2,Player 3", "identity permutation possible");

// permutation properties under the real RNG
g = G.createGame(6, 40);
const before = g.players.map(p => p.name).sort().join(",");
G.shuffleSeats(g);
ok(g.players.map(p => p.name).sort().join(",") === before,
   "real RNG: every player appears exactly once");
ok(g.players.every((p, i) => p.index === i && p.cmdDamage.length === 6),
   "real RNG: indices and matrix width stay consistent");

/* ---- summarizeGame (pure finished-game record) ---- */
section("summarizeGame");
g = G.createGame(3, 40);
G.applyAction(g, { type: "rename", player: 0, name: "Niklas" });
G.applyAction(g, { type: "rename", player: 1, name: "Eva" });
G.applyAction(g, { type: "life", player: 2, delta: -40 }); // Player 3 dies
let rec = G.summarizeGame(g, 0);
ok(rec.playerCount === 3 && rec.startingLife === 40, "count and starting life recorded");
ok(rec.players.join(",") === "Niklas,Eva,Player 3", "all player names listed");
ok(rec.winner === "Niklas", "winner recorded by name, not index");
ok(rec.dead.length === 1 && rec.dead[0] === "Player 3", "dead players recorded by name");
ok(typeof rec.endedAt === "number" && rec.endedAt > 0, "endedAt timestamp set");
ok(g.players.length === 3 && g.players[0].name === "Niklas" && !("winner" in g),
   "pure: game object untouched");
rec = G.summarizeGame(G.deserialize(G.serialize(g)), 1);
ok(rec.winner === "Eva" && rec.dead[0] === "Player 3", "works after deserialize");
ok(G.summarizeGame(g, 99).winner === "", "out-of-range winner -> empty name");
ok(JSON.parse(JSON.stringify(rec)).winner === "Eva", "record is JSON-safe");

/* ---- robustness: corrupt saves and hostile display text ---- */
section("robustness");
function rejects(json, name) {
    let t = false;
    try { G.deserialize(json); } catch (e) { t = true; }
    ok(t, name);
}
rejects('{"schema":1,"players"', "truncated JSON rejected");
rejects('{"schema":1,"players":[{}]}', "empty player object rejected");
rejects('{"schema":1,"players":"two"}', "players as string rejected");
g = G.createGame(2, 40);
let raw = JSON.parse(G.serialize(g));
raw.players[0].life = "forty";
rejects(JSON.stringify(raw), "non-numeric life rejected");
raw = JSON.parse(G.serialize(g));
raw.players[1].cmdDamage = [[0, 0]]; // wrong width
rejects(JSON.stringify(raw), "wrong-width cmdDamage rejected");
raw = JSON.parse(G.serialize(g));
raw.players[0].cmdDamage[1] = [0, "x"];
rejects(JSON.stringify(raw), "non-numeric cmdDamage cell rejected");

raw = JSON.parse(G.serialize(g));
raw.settings = { cmdDamageAffectsLife: "yes", autoDeath: 1 };
raw.history = "nope"; delete raw.log;
let gr = G.deserialize(JSON.stringify(raw));
ok(gr.settings.cmdDamageAffectsLife === true && gr.settings.autoDeath === true,
   "unexpected settings types normalize to defaults");
ok(Array.isArray(gr.history) && Array.isArray(gr.log) && Array.isArray(gr.future),
   "missing/typed-wrong stacks normalize to empty arrays");
raw = JSON.parse(G.serialize(g));
raw.settings.autoDeath = false;
ok(G.deserialize(JSON.stringify(raw)).settings.autoDeath === false,
   "literal false survives normalization");

// hostile display text stays display text: quotes, emoji, RTL, HTML-ish
g = G.createGame(2, 40);
const hostile = '<b>"Nik\\l"</b> 🎉 שלום';
G.applyAction(g, { type: "rename", player: 0, name: hostile });
G.applyAction(g, { type: "addCustomCounter", player: 0, name: '"q\\uote' });
G.applyAction(g, { type: "nameCommander", player: 1, slot: 0, name: "🐢🐢🐢" });
let gh = G.deserialize(G.serialize(g));
ok(gh.players[0].name === hostile.slice(0, 24), "quotes/emoji/RTL/HTML survive round-trip verbatim");
ok(gh.players[0].customCounters[0].name === '"q\\uote', "custom counter name round-trips");
ok(G.commanderLabel(gh.players[1], 0) === "🐢🐢🐢", "emoji commander label intact");
G.undo(g);
ok(g.log[g.log.length - 1].text.indexOf("undo:") === 0, "log text with hostile name still labels undo");

console.log("\n=========================");
console.log(passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
