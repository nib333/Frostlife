import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Dialog {
    id: dialog

    Rectangle { anchors.fill: parent; color: Palette.canvas; z: -1 }

    property int playerCount: app.game.players.length
    property int startingLife: app.game.startingLife

    onAccepted: app.newGame(playerCount, startingLife)

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader { title: qsTr("New game") }

        ComboBox {
            label: qsTr("Players")
            currentIndex: dialog.playerCount - 2
            menu: ContextMenu {
                Repeater {
                    model: 5 // 2..6
                    MenuItem { text: (index + 2) }
                }
            }
            onCurrentIndexChanged: dialog.playerCount = currentIndex + 2
        }

        ComboBox {
            label: qsTr("Starting life")
            currentIndex: { // 20 / 25 / 30 / 40
                var v = dialog.startingLife
                return v === 20 ? 0 : v === 25 ? 1 : v === 30 ? 2 : 3
            }
            menu: ContextMenu {
                MenuItem { text: "20" }
                MenuItem { text: "25" }
                MenuItem { text: "30" }
                MenuItem { text: "40 (Commander)" }
            }
            onCurrentIndexChanged:
                dialog.startingLife = [20, 25, 30, 40][currentIndex]
        }
    }
}
