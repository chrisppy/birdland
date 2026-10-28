// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// Current weather from Open-Meteo (open-meteo.com, no API key). Needs a
// `location` of "latitude,longitude"; refreshes every 15 minutes and on click.
Indicator {
    id: root

    property string location: ""

    property real temperature: NaN
    property int code: -1
    property bool day: true

    function refresh() {
        const [lat, lon] = location.split(",").map(s => s.trim());
        if (!lat || !lon)
            return;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn("bullpen: weather request failed with status", xhr.status);
                return;
            }
            try {
                const current = JSON.parse(xhr.responseText).current;
                temperature = current.temperature_2m;
                code = current.weather_code;
                day = current.is_day === 1;
            } catch (e) {
                console.warn("bullpen: unexpected weather response:", e);
            }
        };
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast" + `?latitude=${lat}&longitude=${lon}` + "&current=temperature_2m,weather_code,is_day" + `&temperature_unit=${imperial ? "fahrenheit" : "celsius"}`);
        xhr.send();
    }

    // WMO weather interpretation codes, as used by Open-Meteo.
    function glyph(code, day) {
        switch (code) {
        case 0:
            return day ? "\u{F0599}" : "\u{F0594}"; // weather_sunny / weather_night
        case 1:
        case 2:
            return day ? "\u{F0595}" : "\u{F0F31}"; // weather_partly_cloudy / weather_night_partly_cloudy
        case 45:
        case 48:
            return "\u{F0591}"; // weather_fog
        case 51:
        case 53:
        case 55:
        case 61:
        case 63:
        case 80:
        case 81:
            return "\u{F0597}"; // weather_rainy
        case 65:
        case 82:
            return "\u{F0596}"; // weather_pouring
        case 56:
        case 57:
        case 66:
        case 67:
            return "\u{F067F}"; // weather_snowy_rainy (freezing drizzle/rain)
        case 71:
        case 73:
        case 75:
        case 77:
        case 85:
        case 86:
            return "\u{F0598}"; // weather_snowy
        case 95:
            return "\u{F067E}"; // weather_lightning_rainy
        case 96:
        case 99:
            return "\u{F0592}"; // weather_hail
        default:
            return "\u{F0590}"; // weather_cloudy (3: overcast, and anything unknown)
        }
    }

    available: location !== "" && code >= 0
    interactive: true
    icon: glyph(code, day)
    label: Math.round(temperature) + "°"

    onClicked: refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: root.location !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
