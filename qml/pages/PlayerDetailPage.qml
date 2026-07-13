import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

/* Everything about one player that isn't the headline life number:
 * counters, commander damage received (per source, per partner slot),
 * monarch / initiative / blessing toggles, rename. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.pal.canvas; z: -1 }
    property int playerIndex: 0
    readonly property var pl: app.rev >= 0 ? app.game.players[playerIndex] : null

    // reusable ± row
    Component {
        id: stepper
        Row {
            property string label
            property int value
            property var onDelta
            spacing: Theme.paddingMedium
            width: parent ? parent.width : 0
            Label {
                text: label
                color: app.pal.primaryText
                width: parent.width * 0.34
                anchors.verticalCenter: parent.verticalCenter
                truncationMode: TruncationMode.Fade
            }
            IconButton {
                icon.source: "image://theme/icon-m-remove"
                onClicked: onDelta(-1)
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: value
                color: app.pal.primaryText
                font.pixelSize: Theme.fontSizeLarge
                width: Theme.itemSizeSmall
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            IconButton {
                icon.source: "image://theme/icon-m-add"
                onClicked: onDelta(1)
                anchors.verticalCenter: parent.verticalCenter
            }
            IconButton { // invisible spacer, same width as the custom rows' remove button
                icon.source: "image://theme/icon-m-clear"
                opacity: 0
                enabled: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

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
                    property var src: app.game.players[index]

                    Loader { sourceComponent: stepper; width: parent.width
                        onLoaded: item.label = src.name + (src.partners ? " · A" : "")
                        Binding { target: item; property: "value"
                                  value: pl ? pl.cmdDamage[index][0] : 0 }
                        Component.onCompleted: item.onDelta = function (d) {
                            app.act({ type: "cmdDamage", player: playerIndex,
                                      source: index, slot: 0, delta: d }) } }
                    Loader { sourceComponent: stepper; width: parent.width
                        active: src.partners
                        visible: src.partners
                        onLoaded: item.label = src.name + " · B"
                        Binding { target: item; property: "value"
                                  value: pl ? pl.cmdDamage[index][1] : 0 }
                        Component.onCompleted: item.onDelta = function (d) {
                            app.act({ type: "cmdDamage", player: playerIndex,
                                      source: index, slot: 1, delta: d }) } }
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

            Loader { sourceComponent: stepper; width: parent.width
                onLoaded: { item.label = qsTr("Poison"); }
                Binding { target: item; property: "value"; value: pl ? pl.counters.poison : 0 }
                Component.onCompleted: item.onDelta = function (d) {
                    app.act({ type: "counter", player: playerIndex, counter: "poison", delta: d }) } }
            Loader { sourceComponent: stepper; width: parent.width
                onLoaded: { item.label = qsTr("Energy"); }
                Binding { target: item; property: "value"; value: pl ? pl.counters.energy : 0 }
                Component.onCompleted: item.onDelta = function (d) {
                    app.act({ type: "counter", player: playerIndex, counter: "energy", delta: d }) } }
            Loader { sourceComponent: stepper; width: parent.width
                onLoaded: { item.label = qsTr("Experience"); }
                Binding { target: item; property: "value"; value: pl ? pl.counters.experience : 0 }
                Component.onCompleted: item.onDelta = function (d) {
                    app.act({ type: "counter", player: playerIndex, counter: "experience", delta: d }) } }
            Loader { sourceComponent: stepper; width: parent.width
                onLoaded: { item.label = qsTr("Commander tax (casts)"); }
                Binding { target: item; property: "value"; value: pl ? pl.counters.cmdTax : 0 }
                Component.onCompleted: item.onDelta = function (d) {
                    app.act({ type: "counter", player: playerIndex, counter: "cmdTax", delta: d }) } }

            Repeater {
                model: app.rev >= 0 ? app.game.players[playerIndex].customCounters.length : 0
                delegate: Row {
                    width: col.width
                    spacing: Theme.paddingSmall
                    readonly property var cc: app.game.players[playerIndex].customCounters[index]
                    Label {
                        text: cc.name
                        color: app.pal.primaryText
                        width: parent.width * 0.34
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-remove"
                        onClicked: app.act({ type: "customCounter", player: playerIndex,
                                             index: index, delta: -1 })
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: cc.value
                        color: app.pal.primaryText
                        font.pixelSize: Theme.fontSizeLarge
                        width: Theme.itemSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-add"
                        onClicked: app.act({ type: "customCounter", player: playerIndex,
                                             index: index, delta: +1 })
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-clear"
                        onClicked: app.act({ type: "removeCustomCounter", player: playerIndex,
                                             index: index })
                        anchors.verticalCenter: parent.verticalCenter
                    }
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
                    readonly property var cs: app.game.players[playerIndex].customStatuses[index]
                    TextSwitch {
                        width: parent.width - removeStatusBtn.width
                        text: cs.name
                        checked: cs.on
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
