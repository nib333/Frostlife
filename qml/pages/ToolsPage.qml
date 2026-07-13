import QtQuick 2.6
import Sailfish.Silica 1.0

/* Game-start utilities: roll-for-first-player, d20, d6, coin flip.
 * Pure UI + Math.random — no engine involvement. Results render big:
 * this page gets read with the phone flat on the table.
 *
 * Layout: a vertical stack of full-width tappable rows, centered on
 * the page, ordered by usage frequency / thumb reach (first-player
 * roll on top, coin last). Tapping anywhere on a row (re-)rolls it.
 * Each die is drawn as its own silhouette — rounded square d6,
 * hexagonal d20 profile, circular coin — with a text label under it. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    property string d6Result: ""
    property string d20Result: ""
    property string coinResult: ""
    property string firstText: ""
    readonly property bool revealing: revealTimer.running
    // d20 is the table workhorse — largest; d6/coin step down. Result
    // numbers scale with their shape.
    readonly property real d20Size: Theme.itemSizeLarge * 2.0
    readonly property real d6Size: Theme.itemSizeLarge * 1.75
    readonly property real coinSize: Theme.itemSizeLarge * 1.75

    Timer { // decelerating name shuffle (~2 s); the tick it settles on is the pick
        id: revealTimer
        property int ticks: 0
        interval: 50
        onTriggered: {
            var players = app.game.players
            page.firstText = players[Math.floor(Math.random() * players.length)].name
            ticks++
            if (ticks < 12) {
                interval = interval * 1.2
                restart()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        PageHeader { id: header; title: qsTr("Tools") }

        Column {
            id: col
            width: parent.width - Theme.horizontalPageMargin * 2
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: header.height / 2   // center below the header
            }
            spacing: Theme.paddingLarge

            MouseArea { // roll for first player — an action, keeps its full label
                width: parent.width
                height: firstCol.height + Theme.paddingMedium * 2
                onClicked: {
                    revealTimer.ticks = 0
                    revealTimer.interval = 50
                    revealTimer.restart()
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.paddingSmall
                    color: app.pal.surfaceAlt
                    opacity: parent.pressed ? 0.5 : 0
                }
                Column {
                    id: firstCol
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall
                    Rectangle { // wide pill: an action container, deliberately
                                // NOT a die shape — same hairline/surface
                                // styling so it reads as tappable
                        width: parent.width * 0.9
                        height: Theme.itemSizeLarge * 1.2
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: height / 2
                        color: app.pal.surface
                        border.color: app.pal.hairline
                        border.width: 2
                        Label {
                            anchors.centerIn: parent
                            width: parent.width - parent.height // clear the rounded ends
                            horizontalAlignment: Text.AlignHCenter
                            text: page.firstText || "–"
                            textFormat: Text.PlainText  // shows player names
                            color: page.firstText === "" ? app.pal.mutedText
                                 : page.revealing ? app.pal.mutedText : app.pal.frostBlue
                            font.pixelSize: Theme.fontSizeHuge * 1.4
                            font.bold: true
                            fontSizeMode: Text.HorizontalFit   // long names shrink to fit
                            minimumPixelSize: Theme.fontSizeMedium
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: page.revealing ? qsTr("Rolling…") : qsTr("Roll for first player")
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            MouseArea { // d20 — hexagonal icosahedron profile
                width: parent.width
                height: d20Col.height + Theme.paddingMedium * 2
                onClicked: page.d20Result = String(Math.floor(Math.random() * 20) + 1)
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.paddingSmall
                    color: app.pal.surfaceAlt
                    opacity: parent.pressed ? 0.5 : 0
                }
                Column {
                    id: d20Col
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall
                    Canvas { // flat-top hexagon, hairline stroke on surface fill
                        width: page.d20Size; height: page.d20Size
                        anchors.horizontalCenter: parent.horizontalCenter
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2, cy = height / 2
                            var r = Math.min(width, height) / 2 - 2
                            ctx.beginPath()
                            for (var i = 0; i < 6; i++) {
                                // vertices at 0°/60°/…: flat edges top + bottom
                                var a = Math.PI / 3 * i
                                var x = cx + r * Math.cos(a), y = cy + r * Math.sin(a)
                                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                            }
                            ctx.closePath()
                            ctx.fillStyle = String(app.pal.surface)
                            ctx.fill()
                            ctx.lineWidth = 2
                            ctx.strokeStyle = String(app.pal.hairline)
                            ctx.stroke()
                        }
                        Label {
                            anchors.centerIn: parent
                            text: page.d20Result || "–"
                            color: page.d20Result ? app.pal.frostBlue : app.pal.mutedText
                            font.pixelSize: page.d20Size * 0.42
                            font.bold: true
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "d20"
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            MouseArea { // d6 — rounded square IS a d6
                width: parent.width
                height: d6Col.height + Theme.paddingMedium * 2
                onClicked: page.d6Result = String(Math.floor(Math.random() * 6) + 1)
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.paddingSmall
                    color: app.pal.surfaceAlt
                    opacity: parent.pressed ? 0.5 : 0
                }
                Column {
                    id: d6Col
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall
                    Rectangle {
                        width: page.d6Size; height: page.d6Size
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: Theme.paddingMedium
                        color: app.pal.surface
                        border.color: app.pal.hairline
                        border.width: 2
                        Label {
                            anchors.centerIn: parent
                            text: page.d6Result || "–"
                            color: page.d6Result ? app.pal.frostBlue : app.pal.mutedText
                            font.pixelSize: page.d6Size * 0.42
                            font.bold: true
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "d6"
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            MouseArea { // coin — circle
                width: parent.width
                height: coinCol.height + Theme.paddingMedium * 2
                onClicked: page.coinResult =
                    Math.random() < 0.5 ? qsTr("Heads") : qsTr("Tails")
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.paddingSmall
                    color: app.pal.surfaceAlt
                    opacity: parent.pressed ? 0.5 : 0
                }
                Column {
                    id: coinCol
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall
                    Rectangle {
                        width: page.coinSize; height: page.coinSize
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: width / 2
                        color: app.pal.surface
                        border.color: app.pal.hairline
                        border.width: 2
                        Label {
                            anchors.centerIn: parent
                            width: parent.width * 0.75
                            horizontalAlignment: Text.AlignHCenter
                            text: page.coinResult || "–"
                            color: page.coinResult ? app.pal.frostBlue : app.pal.mutedText
                            font.pixelSize: page.coinSize * 0.3
                            font.bold: true
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: Theme.fontSizeSmall
                        }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Coin")
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
