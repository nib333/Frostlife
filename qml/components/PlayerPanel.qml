import QtQuick 2.6
import Sailfish.Silica 1.0

/* One player's tile.
 * - Tap left/right half: -1 / +1 life
 * - Press-and-hold left/right: -5 / +5 (repeats while held)
 * - Tap the name row: opens PlayerDetailPage (counters + commander damage)
 * The panel binds to `app.rev` so it refreshes on any game mutation.
 */
Rectangle {
    id: panel

    property int playerIndex: 0
    property bool flipped: false          // rotate 180° for across-the-table players
    // read-through helpers; `app.rev` dependency forces re-evaluation
    readonly property var pl: app.rev >= 0 ? app.game.players[playerIndex] : null

    signal detailRequested(int playerIndex)

    rotation: flipped ? 180 : 0
    color: app.pal.surface
    border.color: pl && pl.monarch ? app.pal.frostBlue : app.pal.hairline
    border.width: pl && pl.monarch ? 2 : 1
    radius: Theme.paddingSmall

    // ---- life tap zones ----
    Row {
        anchors.fill: parent
        Repeater {
            model: 2 // 0 = minus, 1 = plus
            MouseArea {
                width: panel.width / 2
                height: panel.height
                property int sign: index === 0 ? -1 : 1

                onClicked: app.act({ type: "life", player: playerIndex, delta: sign })
                onPressAndHold: holdTimer.start()
                onReleased: holdTimer.stop()
                onCanceled: holdTimer.stop()

                Timer {
                    id: holdTimer
                    interval: 350; repeat: true; triggeredOnStart: true
                    onTriggered: app.act({ type: "life", player: playerIndex, delta: sign * 5 })
                }

                Rectangle { // pressed feedback
                    anchors.fill: parent
                    color: app.pal.surfaceAlt
                    opacity: parent.pressed ? 0.5 : 0
                    Behavior on opacity { FadeAnimation {} }
                }

                Label { // faint +/- affordance
                    text: sign < 0 ? "\u2212" : "+"
                    color: app.pal.mutedText
                    opacity: 0.35
                    font.pixelSize: Theme.fontSizeLarge
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: sign < 0 ? parent.left : undefined
                        right: sign > 0 ? parent.right : undefined
                        margins: Theme.paddingMedium
                    }
                }
            }
        }
    }

    // ---- content (non-interactive, above tap zones visually) ----
    Column {
        anchors.centerIn: parent
        spacing: 0
        width: parent.width

        Label { // life total — the hero number
            text: pl ? pl.life : ""
            color: pl && pl.dead ? app.pal.mutedText : app.pal.primaryText
            font.pixelSize: Math.min(panel.height * 0.42, Theme.fontSizeHuge * 2.2)
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

            // ---- counter stack (under the life number; only toggled-on counters) ----
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 2
                z: 3
            Repeater {
                model: [
                    { key: "poison",     glyph: "\u2620", accent: app.pal.success },
                    { key: "energy",     glyph: "\u26A1", accent: app.pal.warning },
                    { key: "experience", glyph: "\u2727", accent: app.pal.frostBlue },
                    { key: "cmdTax",     glyph: "\u26C1", accent: app.pal.mutedText }
                ]
                delegate: Rectangle {
                    readonly property int cVal: app.rev >= 0 ? panel.pl.counters[modelData.key] : 0
                    visible: cVal > 0   // appears once nonzero, hides at 0
                    radius: height / 2
                    color: Qt.rgba(0.15, 0.20, 0.24, 0.55)
                    border.color: app.pal.hairline
                    border.width: 1
                    width: crow.width + Theme.paddingSmall
                    height: Theme.itemSizeExtraSmall * 0.72
                    Row {
                        id: crow
                        anchors.centerIn: parent
                        spacing: 0
                        MouseArea {
                            width: parent.height * 1.1; height: crow.height
                            onClicked: app.act({ type: "counter", player: playerIndex,
                                                 counter: modelData.key, delta: -1 })
                            Label { text: "\u2212"; anchors.centerIn: parent
                                    color: parent.pressed ? app.pal.frostBlue : app.pal.mutedText
                                    font.pixelSize: Theme.fontSizeMedium }
                        }
                        Label { text: modelData.glyph
                                color: modelData.accent
                                opacity: cVal > 0 ? 1.0 : 0.4
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter }
                        Label { text: cVal
                                color: app.pal.primaryText
                                opacity: cVal > 0 ? 1.0 : 0.4
                                font.pixelSize: Theme.fontSizeSmall
                                width: Theme.fontSizeMedium
                                horizontalAlignment: Text.AlignHCenter
                                anchors.verticalCenter: parent.verticalCenter }
                        MouseArea {
                            width: parent.height * 1.1; height: crow.height
                            onClicked: app.act({ type: "counter", player: playerIndex,
                                                 counter: modelData.key, delta: +1 })
                            Label { text: "+"; anchors.centerIn: parent
                                    color: parent.pressed ? app.pal.frostBlue : app.pal.mutedText
                                    font.pixelSize: Theme.fontSizeMedium }
                        }
                    }
                }
            }
        }

        Row { // status chips (only toggled counters show in the stack)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall
            CounterChip { glyph: "\u265B"; value: 0; alwaysVisible: pl ? pl.monarch : false; accent: app.pal.frostBlue } // ♛ monarch
            CounterChip { glyph: "\u1F5F2"; value: 0; alwaysVisible: pl ? pl.initiative : false; accent: app.pal.frostBlue } // initiative
            Repeater { // custom statuses (shown when on)
                model: app.rev >= 0 ? panel.pl.customStatuses.length : 0
                CounterChip {
                    readonly property var cs: panel.pl.customStatuses[index]
                    glyph: cs.name
                    value: 0
                    alwaysVisible: cs.on
                    accent: app.pal.frostBlue
                }
            }
        }
    }

    // ---- name row (tap → detail page) ----
    MouseArea {
        id: nameArea
        height: nameLabel.height + Theme.paddingMedium * 2
        anchors { top: parent.top; left: parent.left; right: parent.right }
        onClicked: panel.detailRequested(playerIndex)
        Label {
            id: nameLabel
            text: pl ? pl.name : ""
            color: pl && pl.monarch ? app.pal.frostBlue : app.pal.primaryText
            font.pixelSize: Theme.fontSizeMedium
            anchors { top: parent.top; topMargin: Theme.paddingMedium; horizontalCenter: parent.horizontalCenter }
        }
        Rectangle {
            anchors.fill: parent
            color: app.pal.surfaceAlt
            opacity: nameArea.pressed ? 0.5 : 0
        }
    }

    // ---- eliminated overlay ----
    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        color: app.pal.deadOverlay
        visible: pl ? pl.dead : false
        Label {
            text: "\u2620"
            font.pixelSize: Theme.fontSizeHuge
            color: app.pal.mutedText
            anchors.centerIn: parent
        }
        // still allow taps through to fix mistakes (life can be corrected)
        enabled: false
    }
}
