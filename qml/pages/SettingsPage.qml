import QtQuick 2.6
import Sailfish.Silica 1.0

/* Rules settings mutate game.settings via app.setSetting() (serialized
 * with the game save, not undoable). Display settings are app-level
 * ConfigurationValues on the root (app.keepAwake / app.trueBlack). */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.pal.canvas; z: -1 }

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
        }
        VerticalScrollDecorator {}
    }
}
