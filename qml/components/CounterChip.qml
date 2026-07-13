import QtQuick 2.6
import Sailfish.Silica 1.0

/* Small glyph chip: status markers, "+N" overflow, the compact damage
 * aggregate. Purely presentational — callers control visibility.
 * Same width-cap + fade mechanism as CounterPill's label, so every
 * damage-pill rendering path (individual or aggregate/compact) shrinks
 * the same way instead of overflowing the panel. */
Rectangle {
    id: chip
    property string glyph: ""
    property color accent: app.pal.mutedText
    // >0: structural width cap — the glyph shrinks (fade) to honor it.
    // 0 = unconstrained (status/"+N" chips: always short, no cap needed).
    property real maxWidth: 0

    readonly property real _glyphMax: Math.max(0, maxWidth - Theme.paddingMedium * 2)

    radius: height / 2
    color: app.pal.surfaceAlt
    border.color: app.pal.hairline
    border.width: 1
    width: glyphLabel.width + Theme.paddingMedium * 2
    height: Theme.itemSizeExtraSmall * 0.6

    Label {
        id: glyphLabel
        anchors.centerIn: parent
        text: chip.glyph
        textFormat: Text.PlainText  // may carry user status names
        font.pixelSize: Theme.fontSizeExtraSmall
        color: chip.accent
        width: chip.maxWidth > 0 ? Math.min(implicitWidth, chip._glyphMax) : implicitWidth
        truncationMode: TruncationMode.Fade
    }
}
