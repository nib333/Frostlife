import QtQuick 2.6
import Sailfish.Silica 1.0

/* One player's tile.
 * - Tap left/right half: -1 / +1 life
 * - Press-and-hold left/right: -5 / +5 (repeats while held)
 * - Tap the name row: opens PlayerDetailPage (counters + commander damage)
 * The panel binds to `app.rev` so it refreshes on any game mutation.
 *
 * Vertical layout reserves space by construction: name row fixed at the
 * top, status chip row fixed at the bottom, and all pills + the life
 * number live in a clipped middle area between them.
 */
Rectangle {
    id: panel

    property int playerIndex: 0
    property bool flipped: false          // rotate 180° for across-the-table players
    property bool topRow: false           // at the physical screen top: chips need camera-cutout clearance
    // read-through helpers; `app.rev` dependency forces re-evaluation
    readonly property var pl: app.rev >= 0 ? app.game.players[playerIndex] : null

    // ---- compact mode: collapse the pill stack when it can't fit ----
    // max single-commander damage + number of nonzero sources, for the
    // aggregate pill
    readonly property var dmgAgg: {
        if (app.rev < 0 || !pl) return { max: 0, n: 0 }
        var max = 0, n = 0
        for (var s = 0; s < app.game.players.length; s++) {
            if (s === playerIndex) continue
            var dRow = pl.cmdDamage[s]
            if (!dRow) continue
            for (var k = 0; k < 2; k++)
                if (dRow[k] > 0) { n++; if (dRow[k] > max) max = dRow[k] }
        }
        return { max: max, n: n }
    }
    readonly property int counterPillCount: {
        if (app.rev < 0 || !pl) return 0
        var c = 0
        var keys = ["poison", "energy", "experience", "cmdTax"]
        for (var i = 0; i < keys.length; i++) if (pl.counters[keys[i]] > 0) c++
        for (var j = 0; j < pl.customCounters.length; j++)
            if (pl.customCounters[j].value > 0) c++
        return c
    }
    // Estimate the full stack's natural height from pill COUNTS, never
    // from rendered items — sizing the stack from its own layout would
    // be a binding loop. Overestimating slightly just engages compact
    // mode a little early; contentArea clips whatever still won't fit.
    readonly property real _pillH: Theme.itemSizeExtraSmall * 0.72 + Theme.paddingSmall / 2
    readonly property real _lifeH: Math.min(height * 0.42, Theme.fontSizeHuge * 2.2) * 1.2
    readonly property bool compact:
        (dmgAgg.n + counterPillCount) * _pillH + _lifeH > contentArea.height

    signal detailRequested(int playerIndex)

    rotation: flipped ? 180 : 0
    color: app.pal.surface
    border.color: pl && pl.monarch ? app.pal.frostBlue : app.pal.hairline
    border.width: pl && pl.monarch ? 2 : 1
    radius: Theme.paddingSmall
    clip: true   // content must never bleed onto neighboring panels

    // ---- life tap zones: full panel, behind all content ----
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
                    text: sign < 0 ? "−" : "+"
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

    // ---- middle content: damage pills → life number → counter pills.
    // Anchored between the name row and the chip row and clipped, so it
    // cannot overlap either by construction. ----
    Item {
        id: contentArea
        clip: true
        anchors {
            top: nameArea.bottom
            bottom: chipRow.top
            left: parent.left
            right: parent.right
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            Column { // commander damage received — the urgent number, above life
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 2
                visible: !panel.compact
                Repeater {
                    model: app.rev >= 0 ? app.game.players.length * 2 : 0 // source × partner slot
                    delegate: CounterPill {
                        readonly property int src: Math.floor(index / 2)
                        readonly property int slot: index % 2
                        label: app.rev >= 0 && src !== panel.playerIndex
                               ? "⚔ " + app.cmdLabel(src, slot) : ""
                        value: app.rev >= 0 && src !== panel.playerIndex
                               ? panel.pl.cmdDamage[src][slot] : 0
                        accent: app.pal.error
                        action: ({ type: "cmdDamage", player: panel.playerIndex,
                                   source: src, slot: slot })
                    }
                }
            }

            CounterChip { // compact: one aggregate pill; tap opens the full matrix
                visible: panel.compact && panel.dmgAgg.n > 0
                anchors.horizontalCenter: parent.horizontalCenter
                glyph: "⚔ " + panel.dmgAgg.max
                       + (panel.dmgAgg.n > 1 ? " +" + (panel.dmgAgg.n - 1) : "")
                value: 0
                accent: app.pal.error
                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.detailRequested(panel.playerIndex)
                }
            }

            Label { // life total — the hero number
                text: pl ? pl.life : ""
                color: pl && pl.dead ? app.pal.mutedText : app.pal.primaryText
                font.pixelSize: Math.min(panel.height * 0.42, Theme.fontSizeHuge * 2.2)
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Grid { // counter pills: one centered column; two when compact
                anchors.horizontalCenter: parent.horizontalCenter
                columns: panel.compact ? 2 : 1
                columnSpacing: Theme.paddingSmall
                rowSpacing: Theme.paddingSmall / 2
                horizontalItemAlignment: Grid.AlignHCenter
                Repeater {
                    model: [
                        { key: "poison",     glyph: "☠", accent: app.pal.success },
                        { key: "energy",     glyph: "⚡", accent: app.pal.warning },
                        { key: "experience", glyph: "✧", accent: app.pal.frostBlue },
                        { key: "cmdTax",     glyph: "⛁", accent: app.pal.mutedText }
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
        }
    }

    // ---- status chips: fixed-height row pinned to the panel's bottom
    // edge; the 180° rotation carries it, so this is the visual bottom
    // for the player facing the panel ----
    Row {
        id: chipRow
        height: Theme.itemSizeExtraSmall * 0.6   // reserved even when no chip shows
        anchors {
            bottom: parent.bottom
            // top-row panels are flipped, putting this edge at the physical
            // screen top — clear the front-camera cutout there
            bottomMargin: panel.topRow ? Theme.itemSizeExtraSmall : Theme.paddingSmall
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Theme.paddingSmall
        CounterChip { glyph: "♛"; value: 0; alwaysVisible: pl ? pl.monarch : false; accent: app.pal.frostBlue } // ♛ monarch
        CounterChip { glyph: "⚔"; value: 0; alwaysVisible: pl ? pl.initiative : false; accent: app.pal.frostBlue } // ⚔ initiative
        CounterChip { glyph: "♜"; value: 0; alwaysVisible: pl ? pl.cityBlessing : false; accent: app.pal.frostBlue } // ♜ city's blessing
        Repeater { // custom statuses (shown when on)
            model: app.rev >= 0 ? panel.pl.customStatuses.length : 0
            CounterChip {
                glyph: app.rev >= 0 && index < panel.pl.customStatuses.length
                       ? panel.pl.customStatuses[index].name : ""
                value: 0
                alwaysVisible: app.rev >= 0 && index < panel.pl.customStatuses.length
                               ? panel.pl.customStatuses[index].on : false
                accent: app.pal.frostBlue
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
            text: "☠"
            font.pixelSize: Theme.fontSizeHuge
            color: app.pal.mutedText
            anchors.centerIn: parent
        }
        // still allow taps through to fix mistakes (life can be corrected)
        enabled: false
    }
}
