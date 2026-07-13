import QtQuick 2.6
import Sailfish.Silica 1.0

/* Small glyph chip: status markers, "+N" overflow, the compact damage
 * aggregate. Purely presentational — callers control visibility. */
Rectangle {
    id: chip
    property string glyph: ""
    property color accent: app.pal.mutedText

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
    }
}
