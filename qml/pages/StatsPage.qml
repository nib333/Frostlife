import QtQuick 2.6
import Sailfish.Silica 1.0
import "../js/gamestate.js" as Game

/* Per-game stats across all finished games (app.statsRecords, most
 * recent 200). Player NAME is the identity key — normalized via
 * Game.nameKey (trimmed, case-insensitive), displayed with the most
 * recent casing. A genuine rename still splits stats — accepted v1
 * behavior, noted on the page. */
Page {
    id: page

    Rectangle { anchors.fill: parent; color: app.canvasColor; z: -1 }

    RemorsePopup { id: remorse }

    readonly property var records: app.statsRev >= 0 ? app.statsRecords() : []
    readonly property var standings: {
        var byName = {}
        for (var r = 0; r < records.length; r++) {   // oldest → newest
            var rec = records[r]
            for (var p = 0; p < rec.players.length; p++) {
                var key = Game.nameKey(rec.players[p])
                if (!key) continue
                if (!byName[key]) byName[key] = { name: "", played: 0, wins: 0 }
                // newest record wins the displayed casing
                byName[key].name = String(rec.players[p]).trim()
                byName[key].played++
                if (Game.nameKey(rec.winner) === key) byName[key].wins++
            }
        }
        var out = []
        for (var k in byName) out.push(byName[k])
        out.sort(function (a, b) {
            var wa = a.wins / a.played, wb = b.wins / b.played
            if (wb !== wa) return wb - wa
            if (b.wins !== a.wins) return b.wins - a.wins
            return a.name < b.name ? -1 : 1
        })
        return out
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2

        PullDownMenu {
            MenuItem {
                text: qsTr("Clear stats")
                onClicked: remorse.execute(qsTr("Clearing stats"),
                                           function () { app.clearStats() })
            }
        }

        Column {
            id: col
            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingSmall

            PageHeader { title: qsTr("Stats") }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: app.pal.mutedText
                text: qsTr("Stats are keyed by player name (capitalization and spacing ignored) — renaming a player starts a new line.")
            }

            Label {
                width: parent.width
                visible: page.records.length === 0
                horizontalAlignment: Text.AlignHCenter
                color: app.pal.mutedText
                text: qsTr("No finished games yet — use End game in the pulley menu.")
                wrapMode: Text.WordWrap
            }

            SectionHeader { text: qsTr("Standings"); visible: page.records.length > 0 }

            Row { // column headers
                visible: page.records.length > 0
                width: parent.width
                Label { text: qsTr("Player"); width: parent.width * 0.46
                        color: app.pal.mutedText; font.pixelSize: Theme.fontSizeExtraSmall }
                Label { text: qsTr("Games"); width: parent.width * 0.18
                        horizontalAlignment: Text.AlignRight
                        color: app.pal.mutedText; font.pixelSize: Theme.fontSizeExtraSmall }
                Label { text: qsTr("Wins"); width: parent.width * 0.18
                        horizontalAlignment: Text.AlignRight
                        color: app.pal.mutedText; font.pixelSize: Theme.fontSizeExtraSmall }
                Label { text: qsTr("Win %"); width: parent.width * 0.18
                        horizontalAlignment: Text.AlignRight
                        color: app.pal.mutedText; font.pixelSize: Theme.fontSizeExtraSmall }
            }
            Repeater {
                model: page.standings.length
                delegate: Row {
                    width: col.width
                    readonly property var s: index < page.standings.length
                                             ? page.standings[index] : null
                    Label { text: s ? s.name : ""; width: parent.width * 0.46
                            textFormat: Text.PlainText
                            color: app.pal.primaryText; truncationMode: TruncationMode.Fade }
                    Label { text: s ? s.played : ""; width: parent.width * 0.18
                            horizontalAlignment: Text.AlignRight; color: app.pal.primaryText }
                    Label { text: s ? s.wins : ""; width: parent.width * 0.18
                            horizontalAlignment: Text.AlignRight; color: app.pal.primaryText }
                    Label { text: s ? Math.round(100 * s.wins / s.played) + "%" : ""
                            width: parent.width * 0.18
                            horizontalAlignment: Text.AlignRight
                            color: app.pal.frostBlue }
                }
            }

            SectionHeader { text: qsTr("Recent games"); visible: page.records.length > 0 }

            Repeater { // newest first
                model: page.records.length
                delegate: Item {
                    width: col.width
                    height: Theme.itemSizeExtraSmall
                    readonly property var rec: index < page.records.length
                        ? page.records[page.records.length - 1 - index] : null
                    Label {
                        id: dateLabel
                        text: rec ? Qt.formatDateTime(new Date(rec.endedAt), "d MMM hh:mm") : ""
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    }
                    Label {
                        text: rec ? "♛ " + (rec.winner || qsTr("(no winner)")) : ""
                        textFormat: Text.PlainText
                        color: app.pal.primaryText
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                        anchors {
                            left: dateLabel.right; leftMargin: Theme.paddingMedium
                            right: countLabel.left; rightMargin: Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                    }
                    Label {
                        id: countLabel
                        text: rec ? qsTr("%1 pl.").arg(rec.playerCount) : ""
                        color: app.pal.mutedText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
