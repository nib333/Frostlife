import QtQuick 2.6
import Sailfish.Silica 1.0

/* Cover: compact name+life grid for up to 6 players. Monarch in
 * frost-blue, dead players get the ❄☠ frozen-out marker with muted
 * life. Everything binds through app.rev. */
CoverBackground {
    id: cover

    readonly property int n: app.rev >= 0 ? app.game.players.length : 0

    Rectangle { anchors.fill: parent; color: app.canvasColor }

    Grid {
        anchors.centerIn: parent
        columns: cover.n > 3 ? 2 : 1
        columnSpacing: Theme.paddingLarge
        rowSpacing: Theme.paddingSmall
        horizontalItemAlignment: Grid.AlignHCenter

        Repeater {
            model: cover.n
            delegate: Column {
                readonly property var pl: app.rev >= 0 ? app.game.players[index] : null
                readonly property bool dead: pl ? pl.dead : false
                readonly property bool crowned: pl ? pl.monarch : false
                spacing: 0

                Label { // name — stays readable at cover scale, fades if long
                    text: pl ? pl.name : ""
                    color: crowned ? app.pal.frostBlue : app.pal.mutedText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    width: cover.n > 3 ? cover.width * 0.42 : cover.width * 0.8
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                }
                Row { // life, with the frozen-out marker for dead players
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingSmall / 2
                    Label {
                        text: "❄☠"
                        visible: dead
                        color: app.pal.frostBlue
                        opacity: 0.7
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: pl ? pl.life : ""
                        color: dead ? app.pal.mutedText
                             : crowned ? app.pal.frostBlue : app.pal.primaryText
                        font.pixelSize: cover.n > 4 ? Theme.fontSizeMedium : Theme.fontSizeLarge
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    CoverActionList {
        CoverAction { // undo last action
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: app.undoAction()
        }
        CoverAction { // reset game
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.reset()
        }
    }
}
