pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property color backgroundBase: "#f5f5f2"
    readonly property color panelBase: "#ffffff"
    readonly property color panelHover: "#ecefeb"
    readonly property color inverseBase: "#0b0d0f"
    readonly property color inversePanel: "#12161a"

    readonly property color textPrimary: "#111111"
    readonly property color textSecondary: "#555a60"
    readonly property color textMuted: "#8a8f94"
    readonly property color textInverse: "#f6f6f2"

    readonly property color lineSubtle: "#d7d7d2"
    readonly property color lineStrong: "#1e2328"

    readonly property color stateConnected: "#19c37d"
    readonly property color stateWarning: "#e5a400"
    readonly property color stateError: "#d93025"
    readonly property color stateInactive: "#8a8f94"

    readonly property color dataReceived: "#19a663"
    readonly property color dataSent: "#2f80ed"
    readonly property color accentSky: "#5da9f6"
    readonly property color checkMarkGreen: "#19c37d"

    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 6
    readonly property int radiusLarge: 8

    readonly property int fontTiny: 13
    readonly property int fontSmall: 15
    readonly property int fontBody: 16
    readonly property int fontBodyLarge: 18
    readonly property int fontTitle: 36
    readonly property int fontHero: 44
    readonly property int fontLog: 13

    readonly property string bodyFont: Qt.platform.os === "windows" ? "Segoe UI" : "Arial"
    readonly property string monoFont: Qt.platform.os === "windows" ? "Consolas" : (Qt.platform.os === "osx" ? "Menlo" : "monospace")

    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24

    readonly property int tooltipDelay: 850
    readonly property int tooltipTimeout: 6000

    readonly property int motionFast: 110
    readonly property int motionNormal: 170
}
