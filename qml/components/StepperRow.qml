import QtQuick 2.6
import Sailfish.Silica 1.0

/* One label / − / value / + line on the player detail page. Shared by
 * built-in counters, commander damage and custom counters so their
 * alignment is structural. `action` is the app.act() payload without
 * `delta`; the −/+ buttons merge it in. Setting `removeAction` enables
 * the trailing clear button (otherwise kept invisible so all rows keep
 * identical geometry). Callers must bind `value` through app.rev.
 */
Row {
    id: srow

    property alias label: labelItem.text
    property int value: 0
    property var action
    property var removeAction

    spacing: Theme.paddingMedium

    function bump(d) {
        var a = { delta: d }
        for (var k in action) a[k] = action[k]
        app.act(a)
    }

    Label {
        id: labelItem
        color: app.pal.primaryText
        width: srow.width * 0.34
        anchors.verticalCenter: parent.verticalCenter
        truncationMode: TruncationMode.Fade
    }
    IconButton {
        icon.source: "image://theme/icon-m-remove"
        anchors.verticalCenter: parent.verticalCenter
        onClicked: srow.bump(-1)
    }
    Label {
        text: srow.value
        color: app.pal.primaryText
        font.pixelSize: Theme.fontSizeLarge
        width: Theme.itemSizeSmall
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
    }
    IconButton {
        icon.source: "image://theme/icon-m-add"
        anchors.verticalCenter: parent.verticalCenter
        onClicked: srow.bump(1)
    }
    IconButton {
        icon.source: "image://theme/icon-m-clear"
        opacity: srow.removeAction ? 1 : 0
        enabled: !!srow.removeAction
        anchors.verticalCenter: parent.verticalCenter
        onClicked: app.act(srow.removeAction)
    }
}
