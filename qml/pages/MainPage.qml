import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/* Table layout (portrait, 20:9 screen):
 *   2p: stacked, top flipped
 *   3p: two flipped on top row, one full-width bottom
 *   4p: 2×2, top row flipped
 *   5p: 2+2 flipped/normal + one full-width bottom
 *   6p: 3×2, top row flipped
 * MVP keeps 180° flips only (no 90° side seats) — revisit after real-table testing.
 */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: Palette.canvas; z: -1 }
    allowedOrientations: Orientation.Portrait

    readonly property int n: app.rev >= 0 ? app.game.players.length : 2
    readonly property int gutter: Theme.paddingSmall

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height // no scrolling; panels fill the screen

        PullDownMenu {
            MenuItem {
                text: qsTr("New game")
                onClicked: pageStack.push(Qt.resolvedUrl("NewGameDialog.qml"))
            }
            MenuItem {
                text: qsTr("Reset (life %1)").arg(app.game.startingLife)
                onClicked: app.reset()
            }
            MenuItem {
                text: qsTr("Undo")
                enabled: app.canUndo
                onClicked: app.undoAction()
            }
            MenuItem {
                text: qsTr("Redo")
                visible: app.canRedo
                onClicked: app.redoAction()
            }
        }

        Grid {
            id: grid
            anchors { fill: parent; margins: gutter }
            columns: n <= 2 ? 1 : 2
            spacing: gutter

            Repeater {
                model: n
                PlayerPanel {
                    playerIndex: index
                    // top half of the table is flipped to face the players across
                    flipped: index < Math.floor(n / 2) || (n === 2 && index === 0)
                    // odd player counts: last panel spans full width
                    property bool fullRow: (n % 2 === 1) && index === n - 1
                    width: fullRow || n <= 2
                           ? grid.width
                           : (grid.width - gutter) / 2
                    height: {
                        var rows = n <= 2 ? n : Math.ceil(n / 2)
                        return (grid.height - gutter * (rows - 1)) / rows
                    }
                    onDetailRequested: pageStack.push(
                        Qt.resolvedUrl("PlayerDetailPage.qml"),
                        { playerIndex: playerIndex })
                }
            }
        }
    }
}
