// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell

// Current weather from Open-Meteo (open-meteo.com, no API key), shared by
// every bar's weather indicator. Needs a `location` of "latitude,longitude";
// refreshes every 15 minutes while `running`, and on refresh().
Scope {
    id: root

    property string location: ""
    property bool imperial: false
    property bool running: true

    // NaN / -1 until the first answer arrives.
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

    Timer {
        interval: 15 * 60 * 1000
        running: root.running && root.location !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
