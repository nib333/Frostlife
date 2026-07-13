import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.KeepAlive 1.2
import "js/gamestate.js" as Game
import "components"
import "pages"

/* Root window. Owns the single game object and exposes a tiny API the
 * pages use:
 *     app.game               — current game (plain JS object)
 *     app.rev                — bump-on-change revision; bind to it to refresh
 *     app.act(action)        — apply an action (see gamestate.js)
 *     app.undoAction() / app.redoAction() / app.canUndo / app.canRedo
 *     app.newGame(n, life) / app.reset()
 * All mutations autosave (debounced) to dconf via ConfigurationValue.
 */
ApplicationWindow {
    id: app

    property var game: Game.createGame(4, 40)
    property int rev: 0
    property bool canUndo: false
    property bool canRedo: false

    /* Dark-first Frostbite palette (see CLAUDE.md). Lives on the root
     * window as app.pal.* — the qmldir singleton failed to resolve at
     * runtime on-device, leaving default-white Rectangles everywhere. */
    readonly property QtObject pal: QtObject {
        // deep base / gutters; true black = every canvas pixel physically
        // off. Written imperatively by _applyCanvas() — a binding in this
        // inline object did not notify long-lived pages on device.
        property color canvas:               "#0e161d"
        readonly property color surface:     "#1c2832"  // player panels = Frostbite ink
        readonly property color surfaceAlt:  "#26333e"  // raised fills / pressed states
        readonly property color primaryText: "#f4f7f9"  // = Frostbite onInk
        readonly property color mutedText:   "#9aa8b3"
        readonly property color hairline:    "#2b3a45"
        readonly property color frostBlue:   "#7dbfe5"  // accent / active states
        readonly property color success:     "#4ade80"
        readonly property color error:       "#f87171"
        readonly property color warning:     "#fbbf24"
        readonly property color deadOverlay: "#aa0e161d" // dimming for eliminated players
    }

    function _sync() {
        canUndo = Game.canUndo(game)
        canRedo = Game.canRedo(game)
        rev++
        saveTimer.restart()
    }

    function act(action) {
        Game.applyAction(game, action)
        _sync()
    }
    function undoAction() { Game.undo(game); _sync() }
    function redoAction() { Game.redo(game); _sync() }
    function reset() { game = Game.resetGame(game); _sync() }
    function newGame(n, life, shuffleSeating) {
        game = Game.newGameFrom(game, n, life) // identities carry seat-for-seat
        if (shuffleSeating) Game.shuffleSeats(game)
        _sync()
    }

    function maxCmdDamageFor(p) { return Game.maxCmdDamage(game.players[p]) }
    function cmdLabel(sourceIndex, slot) { return Game.commanderLabel(game.players[sourceIndex], slot) }

    // Rules settings live in game.settings (serialized with the save).
    // Changing one is not an undoable action — it goes straight to the
    // game object, then bumps rev + autosaves.
    function setSetting(key, value) {
        if (key === "autoDeath") Game.setAutoDeath(game, value) // retroactive (see engine)
        else game.settings[key] = value
        _sync()
    }

    // ---- app settings (device-level, NOT game state) ----
    ConfigurationValue {
        id: cfgKeepAwake
        key: "/apps/harbour-frostlife/keepAwake"
        defaultValue: true
    }
    ConfigurationValue {
        id: cfgTrueBlack
        key: "/apps/harbour-frostlife/trueBlack"
        defaultValue: false
        onValueChanged: app._applyCanvas()
    }
    // Canvas is the one theme token that changes at runtime (true-black
    // toggle). It lives as a ROOT property — the same proven-reactive
    // path as app.rev — because bindings through the inline pal QtObject
    // did not refresh long-lived pages on device. Pages bind
    // app.canvasColor; pal.canvas is kept in sync.
    property color canvasColor: "#0e161d"
    function _applyCanvas() {
        canvasColor = (cfgTrueBlack.value === true) ? "#000000" : "#0e161d"
        pal.canvas = canvasColor
    }
    property alias keepAwake: cfgKeepAwake.value
    property alias trueBlack: cfgTrueBlack.value

    // ---- persistence (JSON blob in dconf; small state, Harbour-safe) ----
    ConfigurationValue {
        id: savedGame
        key: "/apps/harbour-frostlife/game"
        defaultValue: ""
    }
    Timer { // debounce writes: at most one save per second of activity
        id: saveTimer
        interval: 1000
        onTriggered: savedGame.value = Game.serialize(game)
    }
    Component.onCompleted: {
        _applyCanvas()
        if (savedGame.value && savedGame.value.length > 0) {
            try { game = Game.deserialize(savedGame.value); _sync() }
            catch (e) { console.warn("save restore failed:", e) }
        }
    }
    Connections { // flush pending save when backgrounded
        target: Qt.application
        onStateChanged: if (Qt.application.state !== Qt.ApplicationActive)
            savedGame.value = Game.serialize(game)
    }

    // ---- keep the screen awake while the app is visible (user-gated) ----
    DisplayBlanking {
        preventBlanking: cfgKeepAwake.value === true
                         && Qt.application.state === Qt.ApplicationActive
    }

    initialPage: Component { MainPage {} }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
}
