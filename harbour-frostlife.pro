# Frostlife — pure QML Sailfish app (no C++)
TARGET = harbour-frostlife

CONFIG += sailfishapp_qml

DISTFILES += \
    qml/harbour-frostlife.qml \
    qml/components/PlayerPanel.qml \
    qml/components/CounterPill.qml \
    qml/components/CounterChip.qml \
    qml/components/StepperRow.qml \
    qml/pages/MainPage.qml \
    qml/pages/PlayerDetailPage.qml \
    qml/pages/NewGameDialog.qml \
    qml/pages/EndGameDialog.qml \
    qml/pages/HistoryPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/StatsPage.qml \
    qml/pages/ToolsPage.qml \
    qml/cover/CoverPage.qml \
    qml/js/gamestate.js \
    rpm/harbour-frostlife.spec \
    harbour-frostlife.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
