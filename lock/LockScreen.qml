import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    // The real lock (ext-session-lock). The compositor keeps the session
    // locked until this client explicitly unlocks, even if it crashes.
    WlSessionLock {
        id: sessionLock

        locked: Lock.locked
        onSecureChanged: Lock.secure = secure

        WlSessionLockSurface {
            id: surface

            color: Theme.crust

            LockSurface {
                anchors.fill: parent
                screenName: surface.screen?.name ?? ""
            }
        }
    }

    // Preview: the same UI in overlay windows, without locking anything.
    Variants {
        model: Lock.preview ? Quickshell.screens : []

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-lock-preview"
            WlrLayershell.keyboardFocus: modelData.name === Niri.focusedOutput ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            LockSurface {
                anchors.fill: parent
                screenName: win.modelData.name
                preview: true
            }
        }
    }
}
