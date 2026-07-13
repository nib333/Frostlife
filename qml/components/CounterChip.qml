import QtQuick 2.6
import Sailfish.Silica 1.0

/* Small pill showing an icon/emoji + value; hidden when value is 0
 * unless alwaysVisible. Purely presentational. */
Rectangle {
    id: chip
    property string glyph: ""
    property int value: 0
    property bool alwaysVisible: false
    property color accent: app.pal.mutedText

    visible: alwaysVisible || value > 0
    radius: height / 2
    color: app.pal.surfaceAlt
    border.color: app.pal.hairline
    border.width: 1
    width: row.width + Theme.paddingMedium * 2
    height: Theme.itemSizeExtraSmall * 0.6

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.paddingSmall / 2
        Label {
            text: chip.glyph
            textFormat: Text.PlainText  // may carry user status names
            font.pixelSize: Theme.fontSizeExtraSmall
            color: chip.accent
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: chip.value
            visible: chip.value > 0
            font.pixelSize: Theme.fontSizeExtraSmall
            color: app.pal.primaryText
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
