import QtQuick 2.6
import Sailfish.Silica 1.0

/* Game-start utilities: d6 / d20 / coin flip and roll-for-first-player.
 * Pure UI + Math.random — no engine involvement. The result renders
 * huge: this page gets read with the phone flat on the table. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    property string resultText: "?"
    property string resultCaption: qsTr("d6, d20, coin — or roll for first player")
    readonly property bool revealing: revealTimer.running

    function roll(sides) {
        revealTimer.stop()
        resultText = Math.floor(Math.random() * sides) + 1
        resultCaption = "d" + sides
    }
    function flip() {
        revealTimer.stop()
        resultText = Math.random() < 0.5 ? qsTr("Heads") : qsTr("Tails")
        resultCaption = qsTr("Coin flip")
    }
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
            resultText = players[Math.floor(Math.random() * players.length)].name
            ticks++
            if (ticks < 12) {
                resultCaption = qsTr("Rolling…")
                interval = interval * 1.2
                restart()
            } else {
                resultCaption = qsTr("First player")
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

            // ---- the big glanceable result ----
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.resultText
                color: page.revealing ? app.pal.mutedText : app.pal.frostBlue
                font.pixelSize: Theme.fontSizeHuge * 2.4
                font.bold: true
                fontSizeMode: Text.HorizontalFit   // long player names shrink to fit
                minimumPixelSize: Theme.fontSizeLarge
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.resultCaption
                color: app.pal.mutedText
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { width: 1; height: Theme.paddingLarge } // breathing room

            SectionHeader { text: qsTr("Dice & coin") }

            Row {
                width: parent.width
                spacing: Theme.paddingMedium
                Button {
                    text: "d6"
                    width: (parent.width - Theme.paddingMedium * 2) / 3
                    onClicked: page.roll(6)
                }
                Button {
                    text: "d20"
                    width: (parent.width - Theme.paddingMedium * 2) / 3
                    onClicked: page.roll(20)
                }
                Button {
                    text: qsTr("Coin")
                    width: (parent.width - Theme.paddingMedium * 2) / 3
                    onClicked: page.flip()
                }
            }

            SectionHeader { text: qsTr("First player") }

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
