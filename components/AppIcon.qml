import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services

// Icon for an app id / desktop icon name, with a glyph fallback.
Item {
    id: root

    property string appId
    // Explicit icon name/path; takes precedence over appId lookup.
    property string iconName
    property string fallback: Icons.apps
    property real size: Theme.iconSize
    readonly property string source: Apps.resolveIcon(iconName) || Apps.iconFor(appId)

    implicitWidth: size
    implicitHeight: size

    IconImage {
        anchors.fill: parent
        source: root.source
        visible: root.source !== ""
        asynchronous: true
    }

    Icon {
        anchors.centerIn: parent
        visible: root.source === ""
        text: root.fallback
        size: root.size * 0.9
        color: Theme.subtext0
    }
}
