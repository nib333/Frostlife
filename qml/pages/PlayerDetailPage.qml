import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/* Everything about one player that isn't the headline life number:
 * counters, commander damage received (per source, per partner slot),
 * monarch / initiative / blessing toggles, rename. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }
    property int playerIndex: 0
    readonly property var pl: app.rev >= 0 ? app.game.players[playerIndex] : null

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2

        Column {
            id: col
            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            PageHeader { title: pl ? pl.name : "" }

            TextField {
                width: parent.width
                label: qsTr("Name")
                text: pl ? pl.name : ""
                onActiveFocusChanged: if (!activeFocus && pl && text !== pl.name)
                    app.act({ type: "rename", player: playerIndex, name: text })
            }

            SectionHeader { text: qsTr("Commander") }

            TextSwitch {
                text: qsTr("Partner commanders")
                checked: pl ? pl.partners : false
                automaticCheck: false
                onClicked: app.act({ type: "partners", player: playerIndex, value: !pl.partners })
            }

            TextField {
                width: parent.width
                label: pl && pl.partners ? qsTr("Commander A name") : qsTr("Commander name")
                placeholderText: qsTr("optional, e.g. Thrasios")
                text: pl ? pl.commanderNames[0] : ""
                onActiveFocusChanged: if (!activeFocus && pl && text !== pl.commanderNames[0])
                    app.act({ type: "nameCommander", player: playerIndex, slot: 0, name: text })
            }
            TextField {
                width: parent.width
                visible: pl ? pl.partners : false
                label: qsTr("Commander B name")
                placeholderText: qsTr("optional, e.g. Tymna")
                text: pl ? pl.commanderNames[1] : ""
                onActiveFocusChanged: if (!activeFocus && pl && text !== pl.commanderNames[1])
                    app.act({ type: "nameCommander", player: playerIndex, slot: 1, name: text })
            }

            SectionHeader { text: qsTr("Commander damage received") }

            Repeater {
                model: app.rev >= 0 ? app.game.players.length : 0
                delegate: Column {
                    width: col.width
                    visible: index !== playerIndex
                    spacing: Theme.paddingSmall
                    readonly property var src: app.rev >= 0 ? app.game.players[index] : null

                    StepperRow {
                        width: parent.width
                        label: app.rev >= 0 ? app.cmdLabel(index, 0) : ""
                        value: app.rev >= 0 && pl ? pl.cmdDamage[index][0] : 0
                        action: ({ type: "cmdDamage", player: playerIndex,
                                   source: index, slot: 0 })
                    }
                    StepperRow {
                        width: parent.width
                        visible: src ? src.partners : false
                        label: app.rev >= 0 ? app.cmdLabel(index, 1) : ""
                        value: app.rev >= 0 && pl ? pl.cmdDamage[index][1] : 0
                        action: ({ type: "cmdDamage", player: playerIndex,
                                   source: index, slot: 1 })
                    }
                }
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: app.pal.mutedText
                text: qsTr("Commander damage also deducts life. 21 from a single commander is lethal.")
            }

            SectionHeader { text: qsTr("Counters") }

            StepperRow {
                width: parent.width
                label: qsTr("Poison")
                value: app.rev >= 0 && pl ? pl.counters.poison : 0
                action: ({ type: "counter", player: playerIndex, counter: "poison" })
            }
            StepperRow {
                width: parent.width
                label: qsTr("Energy")
                value: app.rev >= 0 && pl ? pl.counters.energy : 0
                action: ({ type: "counter", player: playerIndex, counter: "energy" })
            }
            StepperRow {
                width: parent.width
                label: qsTr("Experience")
                value: app.rev >= 0 && pl ? pl.counters.experience : 0
                action: ({ type: "counter", player: playerIndex, counter: "experience" })
            }
            StepperRow {
                width: parent.width
                label: qsTr("Commander tax (casts)")
                value: app.rev >= 0 && pl ? pl.counters.cmdTax : 0
                action: ({ type: "counter", player: playerIndex, counter: "cmdTax" })
            }

            Repeater {
                model: app.rev >= 0 ? app.game.players[playerIndex].customCounters.length : 0
                delegate: StepperRow {
                    width: col.width
                    label: app.rev >= 0 && pl && index < pl.customCounters.length
                           ? pl.customCounters[index].name : ""
                    value: app.rev >= 0 && pl && index < pl.customCounters.length
                           ? pl.customCounters[index].value : 0
                    action: ({ type: "customCounter", player: playerIndex, index: index })
                    removeAction: ({ type: "removeCustomCounter", player: playerIndex,
                                     index: index })
                }
            }

            Row {
                width: parent.width
                spacing: Theme.paddingSmall
                visible: app.rev >= 0 && app.game.players[playerIndex].customCounters.length < 8
                TextField {
                    id: newCounterField
                    width: parent.width - addBtn.width - Theme.paddingSmall
                    label: qsTr("New counter name")
                    placeholderText: qsTr("e.g. Charge, Rad, Loyalty")
                    EnterKey.onClicked: addBtn.clicked(null)
                }
                IconButton {
                    id: addBtn
                    icon.source: "image://theme/icon-m-add"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        if (newCounterField.text.trim().length > 0) {
                            app.act({ type: "addCustomCounter", player: playerIndex,
                                      name: newCounterField.text })
                            newCounterField.text = ""
                        }
                    }
                }
            }

            SectionHeader { text: qsTr("Status") }

            TextSwitch {
                text: qsTr("Monarch")
                checked: pl ? pl.monarch : false
                automaticCheck: false
                onClicked: app.act({ type: "monarch", player: playerIndex })
            }
            TextSwitch {
                text: qsTr("Initiative")
                checked: pl ? pl.initiative : false
                automaticCheck: false
                onClicked: app.act({ type: "initiative", player: playerIndex })
            }
            TextSwitch {
                text: qsTr("City's blessing")
                checked: pl ? pl.cityBlessing : false
                automaticCheck: false
                onClicked: app.act({ type: "blessing", player: playerIndex, value: !pl.cityBlessing })
            }
            Repeater { // custom statuses
                model: app.rev >= 0 ? app.game.players[playerIndex].customStatuses.length : 0
                delegate: Row {
                    width: col.width
                    TextSwitch {
                        width: parent.width - removeStatusBtn.width
                        text: app.rev >= 0 && index < pl.customStatuses.length
                              ? pl.customStatuses[index].name : ""
                        checked: app.rev >= 0 && index < pl.customStatuses.length
                                 ? pl.customStatuses[index].on : false
                        automaticCheck: false
                        onClicked: app.act({ type: "customStatus", player: playerIndex, index: index })
                    }
                    IconButton {
                        id: removeStatusBtn
                        icon.source: "image://theme/icon-m-clear"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: app.act({ type: "removeCustomStatus", player: playerIndex, index: index })
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.paddingSmall
                visible: app.rev >= 0 && app.game.players[playerIndex].customStatuses.length < 4
                TextField {
                    id: newStatusField
                    width: parent.width - addStatusBtn.width - Theme.paddingSmall
                    label: qsTr("New status name")
                    placeholderText: qsTr("e.g. Ring-bearer, Suspected")
                    EnterKey.onClicked: addStatusBtn.clicked(null)
                }
                IconButton {
                    id: addStatusBtn
                    icon.source: "image://theme/icon-m-add"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        if (newStatusField.text.trim().length > 0) {
                            app.act({ type: "addCustomStatus", player: playerIndex,
                                      name: newStatusField.text })
                            newStatusField.text = ""
                        }
                    }
                }
            }

        }
        VerticalScrollDecorator {}
    }
}
