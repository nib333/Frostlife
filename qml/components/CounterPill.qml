import QtQuick 2.6
import Sailfish.Silica 1.0

/* Interactive pill on the player panel: −/+ tap zones around a glyph
 * (or custom-counter name) and the value. Hidden while the value is 0.
 * `action` is the app.act() payload without `delta`; the tap zones
 * merge it in. Callers must bind `value`/`label` through app.rev.
 */
Rectangle {
    id: pill

    property string label: ""
    property color accent: app.pal.mutedText
    property int value: 0
    property var action
    // >0: structural width cap — the LABEL shrinks (fade) to honor it;
    // the value and both tap zones never shrink. 0 = unconstrained.
    property real maxWidth: 0

    // room left for the label once pill padding, both tap zones
    // (prow.height * 1.1 each) and the value are reserved
    readonly property real _labelMax: Math.max(0, maxWidth - Theme.paddingSmall
                                               - prow.height * 2.2 - Theme.fontSizeMedium)

    visible: value > 0   // appears once nonzero, hides at 0
    radius: height / 2
    color: Qt.rgba(0.15, 0.20, 0.24, 0.55)
    border.color: app.pal.hairline
    border.width: 1
    width: prow.width + Theme.paddingSmall
    height: Theme.itemSizeExtraSmall * 0.72

    function bump(d) {
        var a = { delta: d }
        for (var k in action) a[k] = action[k]
        app.act(a)
    }

    Row {
        id: prow
        anchors.centerIn: parent
        spacing: 0
        MouseArea {
            width: parent.height * 1.1; height: prow.height
            onClicked: pill.bump(-1)
            Label { text: "−"; anchors.centerIn: parent
                    color: parent.pressed ? app.pal.frostBlue : app.pal.mutedText
                    font.pixelSize: Theme.fontSizeMedium }
        }
        Label { text: pill.label
                textFormat: Text.PlainText  // user names are display text, never markup
                color: pill.accent
                font.pixelSize: Theme.fontSizeMedium
                width: pill.maxWidth > 0 ? Math.min(implicitWidth, pill._labelMax)
                                         : implicitWidth
                truncationMode: TruncationMode.Fade
                anchors.verticalCenter: parent.verticalCenter }
        Label { text: pill.value
                color: app.pal.primaryText
                font.pixelSize: Theme.fontSizeSmall
                width: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter }
        MouseArea {
            width: parent.height * 1.1; height: prow.height
            onClicked: pill.bump(+1)
            Label { text: "+"; anchors.centerIn: parent
                    color: parent.pressed ? app.pal.frostBlue : app.pal.mutedText
                    font.pixelSize: Theme.fontSizeMedium }
        }
    }
}
