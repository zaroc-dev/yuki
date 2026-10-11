pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current weather and forecast from Open-Meteo (no API key). Location comes
// from Settings.d.weatherLocation (a city, or "lat,lon"), else from the IP
// (ipinfo.io). The last result is cached on disk, so the dashboard and lock
// screen show something right away and offline. Lazy: nothing is fetched
// until something reads the weather.
Singleton {
    id: root

    readonly property bool enabled: Settings.d.weather
    // { query, place, fetched, current, hourly, daily } as last fetched/cached.
    property var data: null
    property bool loading: false
    property string error: ""

    // Location setting + unit; a cached result for another query is refetched.
    readonly property string query: `${Settings.d.weatherLocation.trim()}|${Settings.d.fahrenheit ? "F" : "C"}`
    readonly property var current: data?.current ?? null
    readonly property bool available: enabled && current !== null
    readonly property string place: data?.place ?? ""
    readonly property string temp: available ? `${Math.round(current.temperature_2m)}°` : "--°"
    readonly property string feelsLike: available ? `${Math.round(current.apparent_temperature)}°` : "--°"
    readonly property int humidity: current?.relative_humidity_2m ?? 0
    readonly property string wind: available ? `${Math.round(current.wind_speed_10m)} ${Settings.d.fahrenheit ? "mph" : "km/h"}` : ""
    readonly property string condition: available ? describe(current.weather_code) : ""
    readonly property string icon: available ? glyph(current.weather_code, current.is_day) : Icons.weatherUnknown
    // [{ time: Date, temp, code, day }] from the current hour on.
    readonly property var hours: {
        const h = data?.hourly;
        if (!h)
            return [];
        const now = Date.now() - 3600000;
        const out = [];
        for (let i = 0; i < h.time.length && out.length < 8; i++) {
            const t = new Date(h.time[i]);
            if (t.getTime() < now)
                continue;
            out.push({ time: t, temp: h.temperature_2m[i], code: h.weather_code[i], day: h.is_day[i] });
        }
        return out;
    }
    // [{ date: Date, code, max, min, rain }] starting today.
    readonly property var days: {
        const d = data?.daily;
        if (!d)
            return [];
        return d.time.map((t, i) => ({ date: new Date(`${t}T12:00`), code: d.weather_code[i], max: d.temperature_2m_max[i], min: d.temperature_2m_min[i], rain: d.precipitation_probability_max?.[i] ?? 0 }));
    }
    readonly property string sunrise: data?.daily ? Qt.formatTime(new Date(data.daily.sunrise[0]), Settings.d.clock24h ? "HH:mm" : "h:mm AP") : ""
    readonly property string sunset: data?.daily ? Qt.formatTime(new Date(data.daily.sunset[0]), Settings.d.clock24h ? "HH:mm" : "h:mm AP") : ""

    // WMO weather interpretation codes.
    function describe(code) {
        if (code <= 0)
            return "Clear";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if (code === 61 || code === 80)
            return "Light rain";
        if (code === 63 || code === 81)
            return "Rain";
        if (code === 65 || code === 82)
            return "Heavy rain";
        if (code === 66 || code === 67)
            return "Freezing rain";
        if (code === 71 || code === 85)
            return "Light snow";
        if (code === 73 || code === 77)
            return "Snow";
        if (code === 75 || code === 86)
            return "Heavy snow";
        if (code === 95)
            return "Thunderstorm";
        if (code === 96 || code === 99)
            return "Thunderstorm, hail";
        return "Unknown";
    }

    function glyph(code, day = true) {
        if (code <= 1)
            return day ? Icons.weatherSunny : Icons.weatherNight;
        if (code === 2)
            return day ? Icons.weatherPartly : Icons.weatherNightPartly;
        if (code === 3)
            return Icons.weatherCloudy;
        if (code === 45 || code === 48)
            return Icons.weatherFog;
        if (code === 65 || code === 82)
            return Icons.weatherPouring;
        if (code >= 51 && code <= 82)
            return Icons.weatherRainy;
        if (code === 75 || code === 86)
            return Icons.weatherSnowyHeavy;
        if (code >= 71 && code <= 86)
            return Icons.weatherSnowy;
        if (code === 95)
            return Icons.weatherLightningRainy;
        if (code === 96 || code === 99)
            return Icons.weatherHail;
        return Icons.weatherUnknown;
    }

    // Fetch unless the cached result is recent and for the same query.
    function refresh(force = false) {
        if (!enabled || loading || !cache.loaded)
            return;
        const fresh = data && data.query === query && Date.now() - data.fetched < 15 * 60000;
        if (fresh && !force)
            return;
        loading = true;
        error = "";
        watchdog.restart();
        locate((lat, lon, place) => forecast(lat, lon, place));
    }

    function fail(message) {
        console.warn(`Weather: ${message}`);
        error = message;
        loading = false;
        watchdog.stop();
    }

    function get(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root.fail(`${url.split("?")[0]}: HTTP ${xhr.status || "error"}`);
                return;
            }
            let json;
            try {
                json = JSON.parse(xhr.responseText);
            } catch (e) {
                root.fail(`bad response from ${url.split("?")[0]}`);
                return;
            }
            done(json);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function locate(done) {
        const loc = Settings.d.weatherLocation.trim();
        const coords = loc.match(/^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$/);
        if (coords) {
            done(coords[1], coords[2], loc);
        } else if (loc) {
            get(`https://geocoding-api.open-meteo.com/v1/search?count=1&name=${encodeURIComponent(loc)}`, r => {
                const hit = r.results?.[0];
                if (!hit)
                    root.fail(`"${loc}" not found`);
                else
                    done(hit.latitude, hit.longitude, hit.name);
            });
        } else {
            get("https://ipinfo.io/json", r => {
                const [lat, lon] = (r.loc ?? "").split(",");
                if (!lat || !lon)
                    root.fail("couldn't locate by IP");
                else
                    done(lat, lon, r.city ?? "");
            });
        }
    }

    function forecast(lat, lon, place) {
        const f = Settings.d.fahrenheit;
        const query = root.query;
        get("https://api.open-meteo.com/v1/forecast" + `?latitude=${lat}&longitude=${lon}&timezone=auto&forecast_days=6&forecast_hours=24` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day" + "&hourly=temperature_2m,weather_code,is_day" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max" + (f ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""), r => {
            root.data = {
                query: query,
                place: place,
                fetched: Date.now(),
                current: r.current,
                hourly: r.hourly,
                daily: r.daily
            };
            root.loading = false;
            watchdog.stop();
            cache.setText(JSON.stringify(root.data));
            // The location or unit changed while this was in flight.
            if (root.query !== query)
                root.refresh(true);
        });
    }

    onQueryChanged: refresh(true)
    onEnabledChanged: refresh()

    FileView {
        id: cache

        property bool loaded: false

        path: Quickshell.cachePath("weather.json")
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {}
            loaded = true;
            root.refresh();
        }
        onLoadFailed: {
            loaded = true;
            root.refresh();
        }
    }

    // A request that never completes must not block refreshes forever.
    Timer {
        id: watchdog

        interval: 20000
        onTriggered: root.fail("request timed out")
    }

    Timer {
        running: root.enabled
        interval: 30 * 60000
        repeat: true
        onTriggered: root.refresh()
    }
}
