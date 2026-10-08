import QtQuick
import Quickshell.Services.UPower
import qs.config

// power-profiles-daemon selector.
Segmented {
    options: [
        { value: PowerProfile.PowerSaver, label: "Saver", icon: Icons.powerSaver },
        { value: PowerProfile.Balanced, label: "Balanced", icon: Icons.balanced }
    ].concat(PowerProfiles.hasPerformanceProfile ? [{ value: PowerProfile.Performance, label: "Performance", icon: Icons.performance }] : [])
    value: PowerProfiles.profile
    onSelected: v => PowerProfiles.profile = v
}
