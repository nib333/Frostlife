import QtQuick 2.6
import Sailfish.Silica 1.0

/* Pick the winner to close out the game: the record goes to the stats
 * store and a fresh game starts (same players, like reset). The sole
 * survivor is preselected when exactly one player is alive. */
Dialog {
    id: dialog

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    property int winnerIndex: -1
    canAccept: winnerIndex >= 0

    Component.onCompleted: {
        var alive = []
        for (var i = 0; i < app.game.players.length; i++)
            if (!app.game.players[i].dead) alive.push(i)
        if (alive.length === 1) winnerIndex = alive[0]
    }

    onAccepted: app.endGame(winnerIndex)

    Column {
        width: parent.width

        DialogHeader {
            title: qsTr("Who won?")
            acceptText: qsTr("End game")
        }

        Repeater {
            model: app.rev >= 0 ? app.game.players.length : 0
            delegate: BackgroundItem {
                width: parent.width
                readonly property var pl: app.rev >= 0 ? app.game.players[index] : null
                highlighted: down || index === dialog.winnerIndex
                onClicked: dialog.winnerIndex = index
                Label {
                    textFormat: Text.PlainText
                    text: (pl ? pl.name : "")
                          + (pl && pl.dead ? "  ❄☠" : "")
                          + (index === dialog.winnerIndex ? "  ♛" : "")
                    color: index === dialog.winnerIndex ? app.pal.frostBlue
                                                        : app.pal.primaryText
                    truncationMode: TruncationMode.Fade
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; leftMargin: Theme.horizontalPageMargin
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                    }
                }
            }
        }
    }
}
