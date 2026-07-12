pragma Singleton
import QtQuick 2.6

/* Frostbite Life Counter — dark-first palette.
 * Derived from the Frostbite marketplace tokens (see CLAUDE.md).
 * `surface` IS Frostbite ink; `canvas` stays deepest for AMOLED savings. */
QtObject {
    readonly property color canvas:      "#0e161d"  // deep base / gutters
    readonly property color surface:     "#1c2832"  // player panels = Frostbite ink
    readonly property color surfaceAlt:  "#26333e"  // raised fills / pressed states
    readonly property color primaryText: "#f4f7f9"  // = Frostbite onInk
    readonly property color mutedText:   "#9aa8b3"
    readonly property color hairline:    "#2b3a45"
    readonly property color frostBlue:   "#7dbfe5"  // accent / active states
    readonly property color success:     "#4ade80"
    readonly property color error:       "#f87171"
    readonly property color warning:     "#fbbf24"
    readonly property color deadOverlay: "#aa0e161d" // dimming for eliminated players
}
