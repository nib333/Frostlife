import QtQuick 2.6
import Sailfish.Silica 1.0

/* Game-start utilities: d6 / d20 / coin flip and roll-for-first-player.
 * Pure UI + Math.random — no engine involvement. Results render big:
 * this page gets read with the phone flat on the table.
 *
 * The dice/coin controls carry no caption text — each is a large tile
 * whose result IS the button (tap to re-roll), distinguished by shape
 * (the coin is a circle) and a subtle corner marker (6 / 20). Only
 * roll-for-first-player keeps a labeled button: it's an action, not a
 * die. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    property string d6Result: ""
    property string d20Result: ""
    property string coinResult: ""
    property string firstText: ""
    property string firstCaption: ""
    readonly property bool revealing: revealTimer.running

    function rollFirstPlayer() {
        revealTimer.ticks = 0
        revealTimer.interval = 50
        revealTimer.restart()
    }

    Timer { // decelerating name shuffle (~2 s); the tick it settles on is the pick
        id: revealTimer
        property int ticks: 0
        interval: 50
        onTriggered: {
            var players = app.game.players
            firstText = players[Math.floor(Math.random() * players.length)].name
            ticks++
            if (ticks < 12) {
                firstCaption = qsTr("Rolling…")
                interval = interval * 1.2
                restart()
            } else {
                firstCaption = qsTr("First player")
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2

        Column {
            id: col
            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Tools") }

            Row { // d6 | d20 | coin — tap a tile to (re-)roll it
                width: parent.width
                spacing: Theme.paddingMedium
                readonly property real tileW: (width - spacing * 2) / 3

                Rectangle { // d6: near-square die
                    width: parent.tileW; height: parent.tileW
                    radius: Theme.paddingSmall
                    color: app.pal.surface
                    border.color: app.pal.hairline

                    Label {
                        anchors.centerIn: parent
                        text: page.d6Result || "–"
                        color: page.d6Result ? app.pal.frostBlue : app.pal.mutedText
                        font.pixelSize: Theme.fontSizeHuge * 1.4
                        font.bold: true
                    }
                    Label { // corner marker instead of a caption
                        text: "6"
                        color: app.pal.mutedText
                        opacity: 0.6
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.paddingSmall }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.d6Result = String(Math.floor(Math.random() * 6) + 1)
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.paddingSmall
                            color: app.pal.surfaceAlt
                            opacity: parent.pressed ? 0.5 : 0
                        }
                    }
                }

                Rectangle { // d20: rounder die + "20" marker
                    width: parent.tileW; height: parent.tileW
                    radius: Theme.paddingLarge
                    color: app.pal.surface
                    border.color: app.pal.hairline

                    Label {
                        anchors.centerIn: parent
                        text: page.d20Result || "–"
                        color: page.d20Result ? app.pal.frostBlue : app.pal.mutedText
                        font.pixelSize: Theme.fontSizeHuge * 1.4
                        font.bold: true
                    }
                    Label {
                        text: "20"
                        color: app.pal.mutedText
                        opacity: 0.6
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.paddingSmall }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.d20Result = String(Math.floor(Math.random() * 20) + 1)
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.paddingLarge
                            color: app.pal.surfaceAlt
                            opacity: parent.pressed ? 0.5 : 0
                        }
                    }
                }

                Rectangle { // coin: the circle IS the shape cue — no marker
                    width: parent.tileW; height: parent.tileW
                    radius: width / 2
                    color: app.pal.surface
                    border.color: app.pal.hairline

                    Label {
                        anchors.centerIn: parent
                        width: parent.width * 0.8
                        horizontalAlignment: Text.AlignHCenter
                        text: page.coinResult || "–"
                        color: page.coinResult ? app.pal.frostBlue : app.pal.mutedText
                        font.pixelSize: Theme.fontSizeHuge
                        font.bold: true
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.coinResult =
                            Math.random() < 0.5 ? qsTr("Heads") : qsTr("Tails")
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: app.pal.surfaceAlt
                            opacity: parent.pressed ? 0.5 : 0
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge * 2 } // breathing room

            // ---- roll for first player: big glanceable reveal ----
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.firstText
                textFormat: Text.PlainText  // shows player names
                color: page.revealing ? app.pal.mutedText : app.pal.frostBlue
                font.pixelSize: Theme.fontSizeHuge * 2
                font.bold: true
                fontSizeMode: Text.HorizontalFit   // long player names shrink to fit
                minimumPixelSize: Theme.fontSizeLarge
            }
            Label {
                width: parent.width
                visible: page.firstCaption.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: page.firstCaption
                color: app.pal.mutedText
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                text: qsTr("Roll for first player")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: page.rollFirstPlayer()
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: app.pal.mutedText
                text: qsTr("Picks randomly among the %1 players in the current game")
                      .arg(app.rev >= 0 ? app.game.players.length : 2)
            }
        }
        VerticalScrollDecorator {}
    }
}
