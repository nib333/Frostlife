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

        Column { // commander damage received — the urgent number, above life
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall / 2
            Repeater {
                model: app.rev >= 0 ? app.game.players.length * 2 : 0 // source × partner slot
                delegate: CounterChip {
                    readonly property int src: Math.floor(index / 2)
                    readonly property int slot: index % 2
                    glyph: app.rev >= 0 && src !== panel.playerIndex
                           ? "⚔ " + app.cmdLabel(src, slot) : ""
                    value: app.rev >= 0 && src !== panel.playerIndex
                           ? panel.pl.cmdDamage[src][slot] : 0
                    accent: app.pal.error
                }
            }
        }

        Label { // life total — the hero number
            text: pl ? pl.life : ""
            color: pl && pl.dead ? app.pal.mutedText : app.pal.primaryText
            font.pixelSize: Math.min(panel.height * 0.42, Theme.fontSizeHuge * 2.2)
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // ---- counter pills (under the life number; only nonzero show) ----
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall / 2
            Repeater {
                model: [
                    { key: "poison",     glyph: "\u2620", accent: app.pal.success },
                    { key: "energy",     glyph: "\u26A1", accent: app.pal.warning },
                    { key: "experience", glyph: "\u2727", accent: app.pal.frostBlue },
                    { key: "cmdTax",     glyph: "\u26C1", accent: app.pal.mutedText }
                ]
                delegate: CounterPill {
                    label: modelData.glyph
                    accent: modelData.accent
                    value: app.rev >= 0 ? panel.pl.counters[modelData.key] : 0
                    action: ({ type: "counter", player: panel.playerIndex,
                               counter: modelData.key })
                }
            }
            Repeater { // custom counters
                model: app.rev >= 0 ? panel.pl.customCounters.length : 0
                delegate: CounterPill {
                    label: app.rev >= 0 && index < panel.pl.customCounters.length
                           ? panel.pl.customCounters[index].name : ""
                    accent: app.pal.frostBlue
                    value: app.rev >= 0 && index < panel.pl.customCounters.length
                           ? panel.pl.customCounters[index].value : 0
                    action: ({ type: "customCounter", player: panel.playerIndex,
                               index: index })
                }
            }
        }

        Row { // status chips (only toggled counters show in the stack)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall
            CounterChip { glyph: "\u265B"; value: 0; alwaysVisible: pl ? pl.monarch : false; accent: app.pal.frostBlue } // ♛ monarch
            CounterChip { glyph: "\u2694"; value: 0; alwaysVisible: pl ? pl.initiative : false; accent: app.pal.frostBlue } // ⚔ initiative
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
