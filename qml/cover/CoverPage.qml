import QtQuick 2.6
import Sailfish.Silica 1.0

CoverBackground {
    Rectangle { anchors.fill: parent; color: app.canvasColor }

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingSmall
        Repeater {
            model: app.rev >= 0 ? app.game.players.length : 0
            Row {
                spacing: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter
                property var pl: app.game.players[index]
                Label {
                    text: pl.name
                    color: app.pal.mutedText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: pl.life
                    color: pl.dead ? app.pal.mutedText : app.pal.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.reset()
        }
    }
}
