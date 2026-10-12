import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

// Card under a Wi-Fi row for joining it: a password for WPA networks, or the
// 802.1X form for enterprise networks. With no `network` it's "Add network"
// (hidden SSID, any security). Stays open until connected or failed.
Rectangle {
    id: root

    // null = add a (hidden) network by name
    property var network: null
    readonly property bool adding: network === null
    // open | psk | eap
    property string security: adding ? "psk" : Net.isEnterprise(network) ? "eap" : "psk"
    property string eap: "peap"
    property string phase2: "mschapv2"
    // system | file | none
    property string ca: "system"
    property bool advanced: false
    property bool busy: false
    property string error: ""
    // A failed PSK attempt on a network that had no profile is forgotten again.
    property bool wasKnown: false
    property string joiningSsid: ""

    signal finished

    component FormButton: MouseArea {
        id: btn

        property string text
        property bool primary: false

        implicitWidth: label.implicitWidth + 28
        implicitHeight: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: btn.primary ? (btn.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : btn.pressed ? Theme.pressed : btn.containsMouse ? Theme.hover : Qt.alpha(Theme.surface1, 0.6)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            text: btn.text
            font.pixelSize: Theme.smallFontSize + 1
            font.weight: btn.primary ? Font.DemiBold : Font.Normal
            color: btn.primary ? Theme.onAccent : Theme.text
        }
    }

    // Shows the error and puts the cursor where it needs fixing.
    function fail(message, field) {
        busy = false;
        error = message;
        timeout.stop();
        const f = field ?? (security === "open" ? ssidField : password);
        f.focusInput();
        f.selectAll();
    }

    function reasonText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Wrong password";
        case ConnectionFailReason.WifiAuthTimeout:
            return "The network didn't answer in time";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network out of range";
        default:
            return "Couldn't connect";
        }
    }

    function submit() {
        if (busy)
            return;
        error = "";
        const ssid = adding ? ssidField.text.trim() : network.name;
        if (!ssid)
            return fail("Enter the network name", ssidField);
        if (security === "psk" && (password.text.length < 8 || password.text.length > 63))
            return fail("Wi-Fi passwords are 8 to 63 characters", password);
        if (security === "eap" && !identity.text.trim())
            return fail("Enter your username", identity);
        if (security === "eap" && !password.text)
            return fail("Enter your password", password);
        if (security === "eap" && ca === "file" && !caPath.text.trim()) {
            advanced = true;
            return fail("Enter the CA certificate's path", caPath);
        }

        busy = true;
        timeout.restart();
        if (security === "psk" && !adding) {
            wasKnown = network.known;
            network.connectWithPsk(password.text);
            return;
        }
        const s = [];
        if (adding)
            s.push("802-11-wireless.hidden", "yes");
        if (security === "psk")
            s.push("wifi-sec.key-mgmt", "wpa-psk");
        if (security === "eap") {
            s.push("wifi-sec.key-mgmt", "wpa-eap", "802-1x.eap", eap, "802-1x.phase2-auth", phase2, "802-1x.identity", identity.text.trim());
            if (anonymous.text.trim())
                s.push("802-1x.anonymous-identity", anonymous.text.trim());
            if (domain.text.trim())
                s.push("802-1x.domain-suffix-match", domain.text.trim());
            if (ca === "system")
                s.push("802-1x.system-ca-certs", "yes");
            else if (ca === "file")
                s.push("802-1x.ca-cert", Settings.expand(caPath.text.trim()));
        }
        const secret = security === "psk" ? `wifi-sec.psk ${password.text}` : security === "eap" ? `802-1x.password ${password.text}` : "";
        joiningSsid = ssid;
        Net.join(ssid, s, secret);
    }

    implicitHeight: body.implicitHeight + 24
    radius: Theme.innerRadius + 2
    color: Qt.alpha(Theme.surface0, 0.5)
    border.width: 1
    border.color: Theme.surface0

    Component.onCompleted: (adding ? ssidField : security === "eap" ? identity : password).focusInput()

    Connections {
        target: root.adding ? null : root.network

        function onConnectedChanged(): void {
            if (root.busy && root.network.connected) {
                root.busy = false;
                root.finished();
            }
        }

        function onConnectionFailed(reason): void {
            if (!root.busy || root.security !== "psk")
                return;
            if (!root.wasKnown)
                root.network.forget();
            root.fail(root.reasonText(reason));
        }
    }

    Connections {
        target: Net

        function onJoined(ssid): void {
            if (root.busy && ssid === root.joiningSsid) {
                root.busy = false;
                root.finished();
            }
        }

        function onJoinFailed(ssid, message): void {
            if (root.busy && ssid === root.joiningSsid)
                root.fail(message);
        }
    }

    // NetworkManager gives up on its own, but don't spin forever.
    Timer {
        id: timeout

        interval: 75000
        onTriggered: root.fail("Timed out")
    }

    ColumnLayout {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            visible: root.adding
            text: "Add network"
            font.weight: Font.DemiBold
        }

        TextField {
            id: ssidField

            Layout.fillWidth: true
            visible: root.adding
            icon: Icons.wifi(1)
            placeholder: "Network name (SSID)"
            readOnly: root.busy
            onAccepted: root.submit()
            onCancelled: root.finished()
        }

        Segmented {
            visible: root.adding
            options: [
                { value: "open", label: "Open" },
                { value: "psk", label: "Password" },
                { value: "eap", label: "Enterprise" }
            ]
            value: root.security
            onSelected: v => root.security = v
        }

        Segmented {
            visible: root.security === "eap"
            options: [
                { value: "peap", label: "PEAP" },
                { value: "ttls", label: "TTLS" }
            ]
            value: root.eap
            onSelected: v => root.eap = v
        }

        TextField {
            id: identity

            Layout.fillWidth: true
            visible: root.security === "eap"
            icon: Icons.account
            placeholder: "Username"
            readOnly: root.busy
            onAccepted: password.focusInput()
            onCancelled: root.finished()
        }

        TextField {
            id: password

            Layout.fillWidth: true
            visible: root.security !== "open"
            icon: Icons.lock
            placeholder: "Password"
            password: true
            readOnly: root.busy
            onAccepted: root.submit()
            onCancelled: root.finished()
        }

        TextField {
            id: domain

            Layout.fillWidth: true
            visible: root.security === "eap"
            icon: Icons.web
            placeholder: "Domain (optional, e.g. example.org)"
            readOnly: root.busy
            onAccepted: root.submit()
            onCancelled: root.finished()
        }

        // Inner auth, anonymous identity and CA. Defaults fit most networks.
        MouseArea {
            Layout.fillWidth: true
            visible: root.security === "eap"
            implicitHeight: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.advanced = !root.advanced

            RowLayout {
                anchors.fill: parent
                spacing: 6

                StyledText {
                    text: "Advanced"
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                }

                Icon {
                    text: Icons.chevronDown
                    size: 14
                    color: Theme.subtext0
                    rotation: root.advanced ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Theme.anim
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.security === "eap" && root.advanced
            spacing: 8

            StyledText {
                text: "Inner authentication"
                font.pixelSize: Theme.smallFontSize
                color: Theme.overlay2
            }

            Segmented {
                options: [
                    { value: "mschapv2", label: "MSCHAPv2" },
                    { value: "pap", label: "PAP" },
                    { value: "gtc", label: "GTC" }
                ]
                value: root.phase2
                onSelected: v => root.phase2 = v
            }

            TextField {
                id: anonymous

                Layout.fillWidth: true
                icon: Icons.account
                placeholder: "Anonymous identity (optional)"
                readOnly: root.busy
                onAccepted: root.submit()
                onCancelled: root.finished()
            }

            StyledText {
                text: "CA certificate"
                font.pixelSize: Theme.smallFontSize
                color: Theme.overlay2
            }

            Segmented {
                options: [
                    { value: "system", label: "System" },
                    { value: "file", label: "File" },
                    { value: "none", label: "Don't check" }
                ]
                value: root.ca
                onSelected: v => root.ca = v
            }

            TextField {
                id: caPath

                Layout.fillWidth: true
                visible: root.ca === "file"
                icon: Icons.certificate
                placeholder: "Path to .pem / .crt"
                readOnly: root.busy
                onAccepted: root.submit()
                onCancelled: root.finished()
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.ca === "none"
                text: "Without a CA check, anyone imitating this network can capture your password."
                wrapMode: Text.Wrap
                font.pixelSize: Theme.smallFontSize
                color: Theme.peach
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.error !== ""
            text: root.error
            wrapMode: Text.Wrap
            font.pixelSize: Theme.smallFontSize
            color: Theme.red
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Icon {
                id: spinner

                visible: root.busy
                text: Icons.loading
                color: Theme.accent

                RotationAnimation on rotation {
                    running: spinner.visible
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.busy
                text: "Connecting…"
                font.pixelSize: Theme.smallFontSize
                color: Theme.subtext0
            }

            Item {
                Layout.fillWidth: true
                visible: !root.busy
            }

            FormButton {
                text: "Cancel"
                onClicked: root.finished()
            }

            FormButton {
                visible: !root.busy
                text: "Connect"
                primary: true
                onClicked: root.submit()
            }
        }
    }
}
