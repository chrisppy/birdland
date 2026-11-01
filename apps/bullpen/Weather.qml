// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import modules.theme

// The current weather, from the shared WeatherData; click to refresh it.
Indicator {
    id: root

    required property WeatherData weather

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

    available: weather.location !== "" && weather.code >= 0
    interactive: true
    icon: glyph(weather.code, weather.day)
    label: Math.round(weather.temperature) + "°"

    onClicked: weather.refresh()
}
