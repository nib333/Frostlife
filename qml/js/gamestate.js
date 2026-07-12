/*
 * gamestate.js — Frostbite Life Counter core logic
 * Pure JavaScript, no QML dependencies. Imported by QML via:
 *     import "js/gamestate.js" as Game
 * and testable under node via the module.exports shim at the bottom.
 *
 * Design:
 *  - A game is a plain serializable object (JSON-safe). No classes.
 *  - Every mutation goes through applyAction(game, action) which returns a
 *    NEW game object (immutable-style) and pushes the previous state onto
 *    the undo stack. This gives undo/redo and autosave for free.
 *  - Commander damage is an N×N×2 structure:
 *        game.players[r].cmdDamage[sourceIndex][commanderSlot]
 *    (slot 1 exists only when the source player has partners enabled).
 *  - Commander damage optionally also deducts life (MTG rules: it does),
 *    controlled by game.settings.cmdDamageAffectsLife.
 */

var SCHEMA_VERSION = 1;
var MAX_PLAYERS = 6;
var MIN_PLAYERS = 2;
var LETHAL_CMD_DAMAGE = 21;
var MAX_UNDO = 200;
var MAX_CUSTOM_COUNTERS = 8;
var MAX_CUSTOM_STATUSES = 4;

/* ---------- construction ---------- */

function createPlayer(index, startingLife, playerCount) {
    var cmd = [];
    for (var s = 0; s < playerCount; s++)
        cmd.push([0, 0]);           // [commander, partner]
    return {
        index: index,
        name: "Player " + (index + 1),
        life: startingLife,
        counters: {                  // EDH-relevant counters
            poison: 0,
            energy: 0,
            experience: 0,
            cmdTax: 0,               // in casts (cost = 2 * casts)
            cmdTaxPartner: 0
        },
        partners: false,             // this player's commander is a partner pair
        commanderNames: ["", ""],    // optional display names for commander / partner
        customCounters: [],          // user-defined: [{ name, value }], max 8
        customStatuses: [],          // user-defined: [{ name, on }], max 4
        monarch: false,
        initiative: false,
        cityBlessing: false,
        dead: false,
        cmdDamage: cmd               // damage RECEIVED, indexed by source player
    };
}

function createGame(playerCount, startingLife) {
    if (playerCount < MIN_PLAYERS) playerCount = MIN_PLAYERS;
    if (playerCount > MAX_PLAYERS) playerCount = MAX_PLAYERS;
    var players = [];
    for (var i = 0; i < playerCount; i++)
        players.push(createPlayer(i, startingLife, playerCount));
    return {
        schema: SCHEMA_VERSION,
        createdAt: Date.now(),
        startingLife: startingLife,
        settings: {
            cmdDamageAffectsLife: true,
            autoDeath: true          // mark dead at life<=0 / poison>=10 / cmd>=21
        },
        players: players,
        history: [],                 // undo stack of prior snapshots (bounded)
        future: [],                  // redo stack
        log: []                      // human-readable action log (bounded)
    };
}

/* ---------- helpers ---------- */

function clone(obj) {
    return JSON.parse(JSON.stringify(obj));
}

function snapshotOf(game) {
    // Snapshot excludes history/future/log to keep memory bounded.
    return {
        startingLife: game.startingLife,
        settings: clone(game.settings),
        players: clone(game.players)
    };
}

function restoreSnapshot(game, snap) {
    game.startingLife = snap.startingLife;
    game.settings = clone(snap.settings);
    game.players = clone(snap.players);
}

/* Display label for a source player's commander in slot 0|1.
 * Named commander -> its name; unnamed partner pair -> "Name · A"/"Name · B";
 * unnamed single commander -> just the player's name. */
function commanderLabel(sourcePlayer, slot) {
    var n = sourcePlayer.commanderNames[slot];
    if (n) return n;
    if (!sourcePlayer.partners) return sourcePlayer.name;
    return sourcePlayer.name + " \u00b7 " + (slot === 1 ? "B" : "A");
}

function totalCmdDamage(player, sourceIndex) {
    var row = player.cmdDamage[sourceIndex];
    return row ? (row[0] + row[1]) : 0;
}

function maxCmdDamage(player) {
    var m = 0;
    for (var s = 0; s < player.cmdDamage.length; s++) {
        var row = player.cmdDamage[s];
        if (row[0] > m) m = row[0];
        if (row[1] > m) m = row[1];
    }
    return m;
}

function refreshDeath(game, p) {
    if (!game.settings.autoDeath) return;
    var pl = game.players[p];
    pl.dead = pl.life <= 0
        || pl.counters.poison >= 10
        || maxCmdDamage(pl) >= LETHAL_CMD_DAMAGE;
}

function pushLog(game, text) {
    game.log.push({ t: Date.now(), text: text });
    if (game.log.length > 500) game.log.shift();
}

/* ---------- actions ----------
 * action = { type, ...params }
 * Types:
 *   life        { player, delta }
 *   counter     { player, counter, delta }          counter in players[].counters
 *   cmdDamage   { player, source, slot, delta }     slot 0|1 (1 = partner)
 *   monarch     { player }                          exclusive across players
 *   initiative  { player }                          exclusive across players
 *   blessing    { player, value }
 *   partners    { player, value }
 *   rename      { player, name }
 *   nameCommander { player, slot, name }   slot 0|1
 *   addCustomStatus     { player, name }
 *   customStatus        { player, index }        toggle
 *   removeCustomStatus  { player, index }
 *   addCustomCounter    { player, name }
 *   customCounter       { player, index, delta }
 *   removeCustomCounter { player, index }
 *   setLife     { player, value }
 */

function applyAction(game, action) {
    // snapshot BEFORE mutating, for undo
    game.history.push(snapshotOf(game));
    if (game.history.length > MAX_UNDO) game.history.shift();
    game.future = [];   // any new action invalidates redo

    var p, pl, name;

    switch (action.type) {

    case "life":
        pl = game.players[action.player];
        pl.life += action.delta;
        refreshDeath(game, action.player);
        pushLog(game, pl.name + (action.delta >= 0 ? " +" : " ") + action.delta + " life → " + pl.life);
        break;

    case "setLife":
        pl = game.players[action.player];
        pl.life = action.value;
        refreshDeath(game, action.player);
        pushLog(game, pl.name + " life set to " + pl.life);
        break;

    case "counter":
        pl = game.players[action.player];
        if (!(action.counter in pl.counters)) {
            game.history.pop();   // failed action must leave no snapshot
            throw new Error("unknown counter: " + action.counter);
        }
        pl.counters[action.counter] = Math.max(0, pl.counters[action.counter] + action.delta);
        refreshDeath(game, action.player);
        pushLog(game, pl.name + " " + action.counter + " → " + pl.counters[action.counter]);
        break;

    case "cmdDamage":
        pl = game.players[action.player];
        var slot = action.slot || 0;
        var row = pl.cmdDamage[action.source];
        var before = row[slot];
        row[slot] = Math.max(0, row[slot] + action.delta);
        var applied = row[slot] - before;   // clamped actual change
        if (game.settings.cmdDamageAffectsLife && applied !== 0)
            pl.life -= applied;
        refreshDeath(game, action.player);
        pushLog(game, pl.name + " takes " + applied + " cmd dmg from " +
                game.players[action.source].name + (slot === 1 ? " (partner)" : "") +
                " → " + row[slot]);
        break;

    case "monarch":
        for (p = 0; p < game.players.length; p++)
            game.players[p].monarch = (p === action.player) ? !game.players[p].monarch : false;
        pushLog(game, game.players[action.player].monarch
                ? game.players[action.player].name + " is the monarch"
                : "No monarch");
        break;

    case "initiative":
        for (p = 0; p < game.players.length; p++)
            game.players[p].initiative = (p === action.player) ? !game.players[p].initiative : false;
        pushLog(game, game.players[action.player].initiative
                ? game.players[action.player].name + " has the initiative"
                : "No one has the initiative");
        break;

    case "blessing":
        game.players[action.player].cityBlessing = !!action.value;
        break;

    case "partners":
        game.players[action.player].partners = !!action.value;
        break;

    case "addCustomStatus":
        pl = game.players[action.player];
        name = String(action.name || "").trim().slice(0, 16);
        if (!name || pl.customStatuses.length >= MAX_CUSTOM_STATUSES) {
            game.history.pop();
            throw new Error(!name ? "empty status name" : "too many custom statuses");
        }
        pl.customStatuses.push({ name: name, on: false });
        pushLog(game, pl.name + " added status \"" + name + "\"");
        break;

    case "customStatus":
        pl = game.players[action.player];
        var cs = pl.customStatuses[action.index];
        if (!cs) {
            game.history.pop();
            throw new Error("no custom status at index " + action.index);
        }
        cs.on = !cs.on;
        pushLog(game, pl.name + " " + cs.name + " " + (cs.on ? "on" : "off"));
        break;

    case "removeCustomStatus":
        pl = game.players[action.player];
        if (!pl.customStatuses[action.index]) {
            game.history.pop();
            throw new Error("no custom status at index " + action.index);
        }
        pl.customStatuses.splice(action.index, 1);
        break;

    case "addCustomCounter":
        pl = game.players[action.player];
        name = String(action.name || "").trim().slice(0, 16);
        if (!name || pl.customCounters.length >= MAX_CUSTOM_COUNTERS) {
            game.history.pop();   // invalid: no snapshot
            throw new Error(!name ? "empty counter name" : "too many custom counters");
        }
        pl.customCounters.push({ name: name, value: 0 });
        pushLog(game, pl.name + " added counter \"" + name + "\"");
        break;

    case "customCounter":
        pl = game.players[action.player];
        var cc = pl.customCounters[action.index];
        if (!cc) {
            game.history.pop();
            throw new Error("no custom counter at index " + action.index);
        }
        cc.value = Math.max(0, cc.value + action.delta);
        pushLog(game, pl.name + " " + cc.name + " \u2192 " + cc.value);
        break;

    case "removeCustomCounter":
        pl = game.players[action.player];
        if (!pl.customCounters[action.index]) {
            game.history.pop();
            throw new Error("no custom counter at index " + action.index);
        }
        pushLog(game, pl.name + " removed counter \"" + pl.customCounters[action.index].name + "\"");
        pl.customCounters.splice(action.index, 1);
        break;

    case "nameCommander":
        pl = game.players[action.player];
        name = String(action.name || "").slice(0, 24);
        pl.commanderNames[action.slot || 0] = name;
        break;

    case "rename":
        name = String(action.name || "").slice(0, 24);
        game.players[action.player].name = name || ("Player " + (action.player + 1));
        break;

    default:
        // unknown action: roll back the snapshot we pushed
        game.history.pop();
        throw new Error("unknown action type: " + action.type);
    }
    return game;
}

/* ---------- undo / redo ---------- */

function canUndo(game) { return game.history.length > 0; }
function canRedo(game) { return game.future.length > 0; }

function undo(game) {
    if (!canUndo(game)) return game;
    game.future.push(snapshotOf(game));
    restoreSnapshot(game, game.history.pop());
    pushLog(game, "undo");
    return game;
}

function redo(game) {
    if (!canRedo(game)) return game;
    game.history.push(snapshotOf(game));
    restoreSnapshot(game, game.future.pop());
    pushLog(game, "redo");
    return game;
}

/* ---------- reset / serialization ---------- */

function resetGame(game, startingLife) {
    var n = game.players.length;
    var names = game.players.map(function (p) { return p.name; });
    var partners = game.players.map(function (p) { return p.partners; });
    var cmdNames = game.players.map(function (p) { return clone(p.commanderNames); });
    var customs = game.players.map(function (p) {
        return p.customCounters.map(function (c) { return { name: c.name, value: 0 }; });
    });
    var statuses = game.players.map(function (p) {
        return p.customStatuses.map(function (c) { return { name: c.name, on: false }; });
    });
    var fresh = createGame(n, startingLife !== undefined ? startingLife : game.startingLife);
    for (var i = 0; i < n; i++) {
        fresh.players[i].name = names[i];
        fresh.players[i].partners = partners[i];
        fresh.players[i].commanderNames = cmdNames[i];
        fresh.players[i].customCounters = customs[i];
        fresh.players[i].customStatuses = statuses[i];
    }
    fresh.settings = clone(game.settings);
    return fresh;
}

function serialize(game) {
    return JSON.stringify(game);
}

function deserialize(json) {
    var g = JSON.parse(json);
    if (g.schema !== SCHEMA_VERSION)
        throw new Error("unsupported save schema: " + g.schema);
    // minimal shape validation
    if (!g.players || !g.players.length) throw new Error("corrupt save: no players");
    return g;
}

/* ---------- node test shim (inert in QML) ---------- */
if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        SCHEMA_VERSION: SCHEMA_VERSION,
        MAX_CUSTOM_COUNTERS: MAX_CUSTOM_COUNTERS,
        MAX_CUSTOM_STATUSES: MAX_CUSTOM_STATUSES,
        LETHAL_CMD_DAMAGE: LETHAL_CMD_DAMAGE,
        MAX_UNDO: MAX_UNDO,
        createGame: createGame,
        applyAction: applyAction,
        undo: undo, redo: redo,
        canUndo: canUndo, canRedo: canRedo,
        resetGame: resetGame,
        serialize: serialize, deserialize: deserialize,
        totalCmdDamage: totalCmdDamage,
        commanderLabel: commanderLabel,
        maxCmdDamage: maxCmdDamage
    };
}
