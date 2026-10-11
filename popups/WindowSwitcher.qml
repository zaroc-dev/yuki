import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Alt+Tab window switcher on the focused output. The look is picked by
// Settings.d.switcherStyle (cards, list, island); behaviour is shared.
LazyLoader {
    active: Switcher.open

    PanelWindow {
        id: win

        screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "yuki-switcher"
        BackgroundEffect.blurRegion: Region {
            item: Theme.blur ? view.item?.panel ?? null : null
            radius: view.item?.panelRadius ?? 0
        }

        // While open, Alt+Tab reaches us as keys instead of re-running niri's
        // bind (one IPC spawn per press), and so does the Alt release.
        ShortcutInhibitor {
            window: win
            enabled: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.35)
            visible: view.item?.dims ?? false
            opacity: 0
            Component.onCompleted: opacity = 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Switcher.cancel()
        }

        Loader {
            id: view

            anchors.fill: parent
            source: {
                switch (Settings.d.switcherStyle) {
                case "list":
                    return "SwitcherList.qml";
                case "island":
                    return "SwitcherIsland.qml";
                default:
                    return "SwitcherCards.qml";
                }
            }
        }

        Item {
            focus: true
            Keys.onPressed: e => {
                switch (e.key) {
                case Qt.Key_Tab:
                case Qt.Key_Right:
                case Qt.Key_Down:
                    Switcher.next();
                    break;
                case Qt.Key_Backtab:
                case Qt.Key_Left:
                case Qt.Key_Up:
                    Switcher.prev();
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    Switcher.commit();
                    break;
                case Qt.Key_Escape:
                    Switcher.cancel();
                    break;
                default:
                    return;
                }
                e.accepted = true;
            }
            Keys.onReleased: e => {
                if (e.key === Qt.Key_Alt)
                    Switcher.commit();
            }
        }
    }
}
