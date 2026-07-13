import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/* Table layout (portrait, 20:9 screen). Panels flip 180° iff they are
 * NOT in the bottom row (the full-width panel for odd counts, the last
 * pair for even), so everyone across the table reads right-side-up:
 *   2p: stacked, top flipped          3p: pair flipped + full-width bottom
 *   4p: 2×2, top row flipped          5p: two pairs flipped + full-width bottom
 *   6p: 3×2, top two rows flipped
 * MVP keeps 180° flips only (no 90° side seats) — revisit after real-table testing.
 */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }
    allowedOrientations: Orientation.Portrait

    readonly property int n: app.rev >= 0 ? app.game.players.length : 2
    readonly property int gutter: Theme.paddingSmall

    // seats per row: pairs, plus a full-width last row for odd counts;
    // 2 players stack full-width
    readonly property var seatRows: {
        var rows = []
        if (n <= 2) {
            for (var i = 0; i < n; i++) rows.push([i])
        } else {
            for (var j = 0; j + 1 < n; j += 2) rows.push([j, j + 1])
            if (n % 2 === 1) rows.push([n - 1])
        }
        return rows
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height // no scrolling; panels fill the screen

        PullDownMenu {
            MenuItem {
                text: qsTr("New game")
                onClicked: pageStack.push(Qt.resolvedUrl("NewGameDialog.qml"))
            }
            MenuItem {
                text: qsTr("End game")
                onClicked: pageStack.push(Qt.resolvedUrl("EndGameDialog.qml"))
            }
            MenuItem {
                text: qsTr("Reset (life %1)").arg(app.game.startingLife)
                onClicked: app.reset()
            }
            MenuItem {
                text: qsTr("History")
                onClicked: pageStack.push(Qt.resolvedUrl("HistoryPage.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Tools")
                onClicked: pageStack.push(Qt.resolvedUrl("ToolsPage.qml"))
            }
            MenuItem {
                text: qsTr("Stats")
                onClicked: pageStack.push(Qt.resolvedUrl("StatsPage.qml"))
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

        // Explicit rows instead of Grid: Grid sizes a column to its widest
        // child, so a full-width last panel (odd player counts) inflated
        // column 0 and pushed every second panel off the right edge.
        Column {
            id: layout
            anchors { fill: parent; margins: gutter }
            spacing: gutter

            Repeater {
                model: page.seatRows.length
                delegate: Row {
                    readonly property var seats: page.seatRows[index]
                    readonly property bool isTopRow: index === 0
                    readonly property bool isBottomRow: index === page.seatRows.length - 1
                    width: layout.width
                    height: (layout.height - gutter * (page.seatRows.length - 1))
                            / page.seatRows.length
                    spacing: gutter

                    Repeater {
                        model: seats.length
                        delegate: PlayerPanel {
                            readonly property int seat: seats[index]
                            playerIndex: seat
                            topRow: isTopRow
                            // everyone except the bottom row faces the players across
                            flipped: !isBottomRow
                            width: seats.length === 1 ? parent.width
                                                      : (parent.width - gutter) / 2
                            height: parent.height
                            onDetailRequested: pageStack.push(
                                Qt.resolvedUrl("PlayerDetailPage.qml"),
                                { playerIndex: playerIndex })
                        }
                    }
                }
            }
        }
    }
}
