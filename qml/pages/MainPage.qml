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

    // Around-the-table mode (opt-in via Settings): players seated along
    // the phone's long sides. 2-3 players gain nothing from side seats
    // and always use rows.
    readonly property bool around: app.seatingLayout === "around" && n >= 4

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
                model: page.around ? 0 : page.seatRows.length
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
                            cutoutEdge: isTopRow ? "bottom" : ""
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

        // Around-the-table: seats walk the table starting at the upper
        // left — down the left side, across the bottom, up the right
        // side, across the top — so turn order runs around the table.
        // Side seats rotate +90 (left, readable from the phone's left
        // side) / -90 (right) and get the TRANSPOSED cell dimensions
        // (rotation is about the center), so the panel-internal priority
        // layout and compact budget compute from the player's own visual
        // dimensions. 5p adds a full-width upright bottom seat; 6p adds a
        // flipped top seat as well.
        Item {
            id: aroundLayout
            visible: page.around
            anchors { fill: parent; margins: gutter }

            // seat descriptors: cell rect + rotation, in player order
            readonly property var seats: {
                var W = width, H = height, g = page.gutter
                var colW = (W - g) / 2
                if (page.n === 4) {
                    var rH = (H - g) / 2
                    return [
                        { x: 0,        y: 0,      w: colW, h: rH, rot: 90 },
                        { x: 0,        y: rH + g, w: colW, h: rH, rot: 90 },
                        { x: colW + g, y: rH + g, w: colW, h: rH, rot: -90 },
                        { x: colW + g, y: 0,      w: colW, h: rH, rot: -90 }
                    ]
                }
                if (page.n === 5) {
                    var bH = (H - g * 2) * 0.30, sH = (H - g * 2) * 0.35
                    return [
                        { x: 0,        y: 0,              w: colW, h: sH, rot: 90 },
                        { x: 0,        y: sH + g,         w: colW, h: sH, rot: 90 },
                        { x: 0,        y: sH * 2 + g * 2, w: W,    h: bH, rot: 0 },
                        { x: colW + g, y: sH + g,         w: colW, h: sH, rot: -90 },
                        { x: colW + g, y: 0,              w: colW, h: sH, rot: -90 }
                    ]
                }
                if (page.n === 6) {
                    var tH = (H - g * 3) * 0.22, mH = (H - g * 3) * 0.28
                    return [
                        { x: 0,        y: tH + g,              w: colW, h: mH, rot: 90 },
                        { x: 0,        y: tH + mH + g * 2,     w: colW, h: mH, rot: 90 },
                        { x: 0,        y: tH + mH * 2 + g * 3, w: W,    h: tH, rot: 0 },
                        { x: colW + g, y: tH + mH + g * 2,     w: colW, h: mH, rot: -90 },
                        { x: colW + g, y: tH + g,              w: colW, h: mH, rot: -90 },
                        { x: 0,        y: 0,                   w: W,    h: tH, rot: 180 }
                    ]
                }
                return []
            }

            Repeater {
                model: aroundLayout.seats.length
                delegate: PlayerPanel {
                    readonly property var seat: aroundLayout.seats[index]
                    readonly property bool side: seat.rot === 90 || seat.rot === -90

                    playerIndex: index
                    seatRotation: seat.rot
                    // every around-mode panel is wide-aspect (side seats
                    // by transposition, top/bottom by full width) — the
                    // tall stacked arrangement is exclusively rows-mode
                    wideLayout: true
                    // side seats: transposed — panel width runs along the
                    // screen's vertical
                    width: side ? seat.h : seat.w
                    height: side ? seat.w : seat.h
                    x: seat.x + (seat.w - width) / 2
                    y: seat.y + (seat.h - height) / 2
                    // whichever LOCAL edge lies along the physical screen
                    // top gets the camera-cutout clearance
                    cutoutEdge: seat.rot === 180 ? "bottom"
                              : seat.y === 0 && seat.rot === 90 ? "left"
                              : seat.y === 0 && seat.rot === -90 ? "right"
                              : ""
                    onDetailRequested: pageStack.push(
                        Qt.resolvedUrl("PlayerDetailPage.qml"),
                        { playerIndex: playerIndex })
                }
            }
        }
    }
}
