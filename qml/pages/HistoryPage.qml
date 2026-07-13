import QtQuick 2.6
import Sailfish.Silica 1.0

/* Action history: undo/redo up top, then the engine's bounded log
 * (game.log, newest first). Read-only view — all mutation goes through
 * app.undoAction()/app.redoAction(). */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.pal.canvas; z: -1 }

    // newest first; rebuilt on every mutation via app.rev
    readonly property var entries: {
        if (app.rev < 0) return []
        var l = app.game.log
        var out = []
        for (var i = l.length - 1; i >= 0; i--) out.push(l[i])
        return out
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: page.entries.length

        header: Column {
            width: list.width

            PageHeader { title: qsTr("History") }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
                Button {
                    text: qsTr("Undo")
                    enabled: app.canUndo
                    onClicked: app.undoAction()
                }
                Button {
                    text: qsTr("Redo")
                    enabled: app.canRedo
                    onClicked: app.redoAction()
                }
            }

            Item { width: 1; height: Theme.paddingLarge } // breathing room
        }

        delegate: Item {
            width: list.width
            height: Theme.itemSizeExtraSmall
            readonly property var entry: index < page.entries.length
                                         ? page.entries[index] : null
            Label {
                id: timeLabel
                text: entry ? Qt.formatTime(new Date(entry.t), "hh:mm:ss") : ""
                color: app.pal.mutedText
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
            }
            Label {
                text: entry ? entry.text : ""
                color: app.pal.primaryText
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
                anchors {
                    left: timeLabel.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        ViewPlaceholder {
            enabled: page.entries.length === 0
            text: qsTr("No actions yet")
        }

        VerticalScrollDecorator {}
    }
}
