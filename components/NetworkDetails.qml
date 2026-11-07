import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Addresses of one interface (IPv4, gateway, DNS, IPv6, MAC) from
// `nmcli device show`, refreshed when NetworkManager reports a change.
GridLayout {
    id: root

    required property string iface
    property string mac
    readonly property var info: Net.details[iface] ?? null

    function refresh() {
        Net.refreshDetails(iface);
    }

    visible: info !== null && (info.ip4.length > 0 || info.ip6.length > 0)
    columns: 2
    columnSpacing: 16
    rowSpacing: 4

    Component.onCompleted: refresh()
    onIfaceChanged: refresh()

    Connections {
        target: Net

        function onChanged(): void {
            root.refresh();
        }
    }

    Repeater {
        model: {
            const i = root.info;
            if (!i)
                return [];
            const rows = [["IPv4", i.ip4.join(", ")], ["Gateway", i.gateway], ["DNS", i.dns.join(", ")], ["IPv6", i.ip6.join(", ")], ["MAC", root.mac]];
            return rows.filter(r => r[1]).reduce((a, r) => a.concat(r), []);
        }

        StyledText {
            required property string modelData
            required property int index

            Layout.fillWidth: index % 2 === 1
            Layout.alignment: Qt.AlignTop
            text: modelData
            wrapMode: Text.WrapAnywhere
            font.pixelSize: Theme.smallFontSize
            color: index % 2 === 1 ? Theme.subtext1 : Theme.overlay1
        }
    }
}
