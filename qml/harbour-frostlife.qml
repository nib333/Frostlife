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
    function newGame(n, life) { game = Game.createGame(n, life); _sync() }

    function maxCmdDamageFor(p) { return Game.maxCmdDamage(game.players[p]) }
    function cmdLabel(sourceIndex, slot) { return Game.commanderLabel(game.players[sourceIndex], slot) }

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

    // ---- keep the screen awake while the app is visible ----
    DisplayBlanking {
        preventBlanking: Qt.application.state === Qt.ApplicationActive
    }

    initialPage: Component { MainPage {} }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
}
