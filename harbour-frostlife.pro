# Frostbite Life Counter — pure QML Sailfish app (no C++)
TARGET = harbour-frostlife

CONFIG += sailfishapp_qml

DISTFILES += \
    qml/harbour-frostlife.qml \
    qml/components/qmldir \
    qml/components/Palette.qml \
    qml/components/PlayerPanel.qml \
    qml/components/CounterChip.qml \
    qml/pages/MainPage.qml \
    qml/pages/PlayerDetailPage.qml \
    qml/pages/NewGameDialog.qml \
    qml/cover/CoverPage.qml \
    qml/js/gamestate.js \
    rpm/harbour-frostlife.spec \
    harbour-frostlife.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
