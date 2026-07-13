import QtQuick 2.6
import Sailfish.Silica 1.0

/* Rules settings mutate game.settings via app.setSetting() (serialized
 * with the game save, not undoable). Display settings are app-level
 * ConfigurationValues on the root (app.keepAwake / app.trueBlack). */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2

        Column {
            id: col
            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            SectionHeader { text: qsTr("Rules") }

            TextSwitch {
                text: qsTr("Commander damage reduces life")
                description: qsTr("Damage entered in the matrix also deducts life")
                checked: app.rev >= 0 && app.game.settings.cmdDamageAffectsLife
                automaticCheck: false
                onClicked: app.setSetting("cmdDamageAffectsLife",
                                          !app.game.settings.cmdDamageAffectsLife)
            }
            TextSwitch {
                text: qsTr("Automatic death detection")
                description: qsTr("Life ≤ 0, poison ≥ 10, or 21 damage from one commander")
                checked: app.rev >= 0 && app.game.settings.autoDeath
                automaticCheck: false
                onClicked: app.setSetting("autoDeath", !app.game.settings.autoDeath)
            }

            SectionHeader { text: qsTr("Table") }

            ComboBox {
                label: qsTr("Seating layout")
                description: qsTr("Around the table seats players along the phone's sides (4+ players)")
                currentIndex: app.seatingLayout === "around" ? 1 : 0
                menu: ContextMenu {
                    MenuItem { text: qsTr("Rows") }
                    MenuItem { text: qsTr("Around the table") }
                }
                onCurrentIndexChanged:
                    app.seatingLayout = currentIndex === 1 ? "around" : "rows"
            }

            SectionHeader { text: qsTr("Display") }

            TextSwitch {
                text: qsTr("Keep screen awake")
                description: qsTr("Prevent display blanking while the app is open")
                checked: app.keepAwake === true
                automaticCheck: false
                onClicked: app.keepAwake = !(app.keepAwake === true)
            }
            TextSwitch {
                text: qsTr("True black background")
                description: qsTr("Maximum AMOLED battery savings")
                checked: app.trueBlack === true
                automaticCheck: false
                onClicked: app.trueBlack = !(app.trueBlack === true)
            }

            SectionHeader { text: qsTr("About") }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: app.pal.primaryText
                text: qsTr("Frostbite Life Counter")
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: app.pal.mutedText
                text: qsTr("No network access — all data stays on your device.")
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: app.pal.primaryText
                text: qsTr("How to use")
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: app.pal.mutedText
                textFormat: Text.PlainText
                text: qsTr("Tap a panel's left/right half for −1/+1 life; press and hold for −5/+5 (repeats).\n"
                    + "Tap a player's name for commander damage, counters and statuses — \"+N\" pills open the same page.\n"
                    + "Pull down for new game, undo, history, tools and stats. Reset can be undone.")
            }
        }
        VerticalScrollDecorator {}
    }
}
