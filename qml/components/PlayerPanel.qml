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
    // nonzero counter pills in priority order (built-ins, then customs)
    readonly property var counterPills: {
        if (app.rev < 0 || !pl) return []
        var out = []
        var defs = [
            { key: "poison",     glyph: "☠", accent: app.pal.success },
            { key: "energy",     glyph: "⚡", accent: app.pal.warning },
            { key: "experience", glyph: "✧", accent: app.pal.frostBlue },
            { key: "cmdTax",     glyph: "⛁", accent: app.pal.mutedText }
        ]
        for (var i = 0; i < defs.length; i++)
            if (pl.counters[defs[i].key] > 0)
                out.push({ label: defs[i].glyph, accent: defs[i].accent,
                           value: pl.counters[defs[i].key],
                           action: { type: "counter", player: playerIndex,
                                     counter: defs[i].key } })
        for (var j = 0; j < pl.customCounters.length; j++)
            if (pl.customCounters[j].value > 0)
                out.push({ label: pl.customCounters[j].name, accent: app.pal.frostBlue,
                           value: pl.customCounters[j].value,
                           action: { type: "customCounter", player: playerIndex,
                                     index: j } })
        return out
    }
    // Estimate heights from pill COUNTS, never from rendered items —
    // sizing the stack from its own layout would be a binding loop.
    // Overestimating slightly just drops into compact/overflow early;
    // contentArea clips whatever still won't fit.
    readonly property real _pillH: Theme.itemSizeExtraSmall * 0.72 + Theme.paddingSmall / 2
    readonly property real _lifeH: Math.min(height * 0.42, Theme.fontSizeHuge * 2.2) * 1.2
    readonly property bool compact:
        (dmgAgg.n + counterPills.length) * _pillH + _lifeH > contentArea.height

    // ---- space priority: life, then damage pill(s), then counters ----
    // counters only get what remains after life + damage are reserved
    readonly property int counterCapacity: {
        var dmgH = compact ? (dmgAgg.n > 0 ? _pillH : 0) : dmgAgg.n * _pillH
        var rows = Math.max(0, Math.floor((contentArea.height - _lifeH - dmgH) / _pillH))
        return compact ? rows * 2 : rows
    }
    readonly property int countersShown: counterPills.length <= counterCapacity
        ? counterPills.length
        : Math.max(0, counterCapacity - 1)   // one slot goes to the "+N" pill

    // ---- status chips, capped to the panel width with a "+N" chip ----
    readonly property var statusChips: {
        if (app.rev < 0 || !pl) return []
        var out = []
        if (pl.monarch) out.push("♛")
        if (pl.initiative) out.push("⚔")
        if (pl.cityBlessing) out.push("♜")
        for (var j = 0; j < pl.customStatuses.length; j++)
            if (pl.customStatuses[j].on) out.push(pl.customStatuses[j].name)
        return out
    }
    function _chipW(text) { // estimated CounterChip width (label + padding)
        return text.length * Theme.fontSizeExtraSmall * 0.7 + Theme.paddingMedium * 2
    }
    readonly property int chipsShown: {
        var avail = width - Theme.paddingMedium * 2
        var gap = Theme.paddingSmall
        var total = 0
        for (var i = 0; i < statusChips.length; i++)
            total += _chipW(statusChips[i]) + (i ? gap : 0)
        if (total <= avail) return statusChips.length
        avail -= _chipW("+9") + gap          // reserve room for the overflow chip
        var used = 0, n = 0
        for (var j = 0; j < statusChips.length; j++) {
            used += _chipW(statusChips[j]) + (j ? gap : 0)
            if (used > avail) break
            n++
        }
        return n
    }

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

            Grid { // counter pills: one centered column; two when compact.
                   // Only countersShown render — counters get the leftover
                   // space, never the damage pill's or life number's.
                anchors.horizontalCenter: parent.horizontalCenter
                columns: panel.compact ? 2 : 1
                columnSpacing: Theme.paddingSmall
                rowSpacing: Theme.paddingSmall / 2
                horizontalItemAlignment: Grid.AlignHCenter
                Repeater {
                    model: panel.countersShown
                    delegate: CounterPill {
                        readonly property var cp: index < panel.counterPills.length
                                                  ? panel.counterPills[index] : null
                        label: cp ? cp.label : ""
                        accent: cp ? cp.accent : app.pal.mutedText
                        value: cp ? cp.value : 0
                        action: cp ? cp.action : ({})
                    }
                }
                CounterChip { // "+N" overflow; tap opens the detail page
                    visible: panel.counterPills.length > panel.countersShown
                    glyph: "+" + (panel.counterPills.length - panel.countersShown)
                    value: 0
                    accent: app.pal.mutedText
                    MouseArea {
                        anchors.fill: parent
                        onClicked: panel.detailRequested(panel.playerIndex)
                    }
                }
            }
        }
    }

    // ---- status chips: fixed-height row pinned to the panel's bottom
    // edge; the 180° rotation carries it, so this is the visual bottom
    // for the player facing the panel ----
    Item {
        id: chipRow
        height: Theme.itemSizeExtraSmall * 0.6   // reserved even when no chip shows
        clip: true                               // never past the panel edge
        anchors {
            bottom: parent.bottom
            // top-row panels are flipped, putting this edge at the physical
            // screen top — clear the front-camera cutout there
            bottomMargin: panel.topRow ? Theme.itemSizeExtraSmall : Theme.paddingSmall
            left: parent.left
            right: parent.right
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall
            Repeater { // active chips (♛ / ⚔ / ♜ / custom), capped to fit
                model: panel.chipsShown
                CounterChip {
                    glyph: index < panel.statusChips.length ? panel.statusChips[index] : ""
                    value: 0
                    alwaysVisible: true
                    accent: app.pal.frostBlue
                }
            }
            CounterChip { // "+N" overflow; tap opens the detail page
                visible: panel.statusChips.length > panel.chipsShown
                glyph: "+" + (panel.statusChips.length - panel.chipsShown)
                value: 0
                accent: app.pal.frostBlue
                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.detailRequested(panel.playerIndex)
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
            text: "☠"
            font.pixelSize: Theme.fontSizeHuge
            color: app.pal.mutedText
            anchors.centerIn: parent
        }
        // still allow taps through to fix mistakes (life can be corrected)
        enabled: false
    }
}
