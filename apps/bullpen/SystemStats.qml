// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io

// Samples CPU, memory and GPU usage and CPU/GPU temperatures while `running`.
// Usage values are 0-1 and temperatures °C; they stay -1 / NaN until known,
// and for sensors this machine doesn't have.
//
// Sources: /proc/stat and /proc/meminfo; hwmon for temperatures. GPU usage,
// first match wins:
// - AMD: the DRM gpu_busy_percent file.
// - Intel: the time not spent in the render engine's idle state (RC6 on i915,
//   gt-c6 on xe), from its residency counter in sysfs.
// - NVIDIA: nvidia-smi, only when neither of the above exists, because it
//   keeps a sleeping NVIDIA GPU awake.
Scope {
    id: root

    property bool running: true
    property bool sampleGpu: true
    property int interval: 2000

    property real cpuUsage: -1
    property real memoryUsage: -1
    property real gpuUsage: -1
    property real cpuTemp: NaN
    property real gpuTemp: NaN

    property string cpuTempPath: ""
    property string gpuTempPath: ""
    property string gpuBusyPath: ""
    property string gpuIdlePath: ""
    property bool hasNvidiaSmi: false
    readonly property string intelIdlePath: gpuBusyPath === "" ? gpuIdlePath : ""
    readonly property bool useNvidia: sampleGpu && hasNvidiaSmi && gpuBusyPath === "" && gpuIdlePath === ""

    property real lastCpuTotal: -1
    property real lastCpuIdle: 0
    property real lastGpuIdleMs: -1
    property real lastGpuIdleAt: 0

    // "cpu  user nice system idle iowait irq softirq steal ..." in clock ticks.
    function parseStat(text) {
        const fields = text.slice(0, text.indexOf("\n")).trim().split(/\s+/).slice(1, 9).map(Number);
        const idle = fields[3] + fields[4];
        const total = fields.reduce((sum, value) => sum + value, 0);
        if (lastCpuTotal >= 0 && total > lastCpuTotal)
            cpuUsage = 1 - (idle - lastCpuIdle) / (total - lastCpuTotal);
        lastCpuTotal = total;
        lastCpuIdle = idle;
    }

    function parseMeminfo(text) {
        const kib = key => Number((text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) ?? [])[1] ?? 0);
        const total = kib("MemTotal");
        if (total > 0)
            memoryUsage = 1 - kib("MemAvailable") / total;
    }

    // Intel: a cumulative count of milliseconds the GPU spent idle. Busy is the
    // share of wall time since the last sample it was not idle. Skips the
    // first sample and counter wraparound (i915's is 32-bit).
    function parseGpuIdle(idleMs, now) {
        if (lastGpuIdleMs >= 0 && now > lastGpuIdleAt && idleMs >= lastGpuIdleMs)
            gpuUsage = Math.max(0, Math.min(1, 1 - (idleMs - lastGpuIdleMs) / (now - lastGpuIdleAt)));
        lastGpuIdleMs = idleMs;
        lastGpuIdleAt = now;
    }

    // Lines from the probe below: "temp<TAB>chip<TAB>label<TAB>path",
    // "gpu-busy<TAB>path", "gpu-idle<TAB>path" and "nvidia".
    function parseSensors(text) {
        const temps = [];
        for (const line of text.split("\n")) {
            const f = line.split("\t");
            if (f[0] === "temp")
                temps.push({
                    chip: f[1],
                    label: f[2],
                    path: f[3]
                });
            else if (f[0] === "gpu-busy" && gpuBusyPath === "")
                gpuBusyPath = f[1];
            else if (f[0] === "gpu-idle" && gpuIdlePath === "")
                gpuIdlePath = f[1];
            else if (f[0] === "nvidia")
                hasNvidiaSmi = true;
        }

        // First matching chip wins; within it, the preferred label, else its first sensor.
        const pick = choices => {
            for (const choice of choices) {
                const chip = temps.filter(t => t.chip === choice.chip);
                const preferred = chip.find(t => choice.labels.includes(t.label)) ?? chip[0];
                if (preferred)
                    return preferred.path;
            }
            return "";
        };
        cpuTempPath = pick([
            {
                chip: "k10temp",
                labels: ["Tctl", "Tdie"]
            },
            {
                chip: "zenpower",
                labels: ["Tdie", "Tctl"]
            },
            {
                chip: "coretemp",
                labels: ["Package id 0"]
            },
            {
                chip: "cpu_thermal",
                labels: []
            },
            {
                chip: "acpitz",
                labels: []
            }
        ]);
        gpuTempPath = pick([
            {
                chip: "amdgpu",
                labels: ["edge"]
            },
            {
                chip: "nouveau",
                labels: []
            },
            {
                chip: "xe",
                labels: ["pkg"]
            },
            {
                chip: "i915",
                labels: []
            }
        ]);
    }

    // Find the sensors once. hwmonN numbering isn't stable, so look them up by name.
    Process {
        running: true
        command: ["sh", "-c", `
            for f in /sys/class/hwmon/hwmon*/temp*_input; do
              [ -r "$f" ] || continue
              d=\${f%/*}; n=\${f##*/}; n=\${n%_input}
              printf 'temp\\t%s\\t%s\\t%s\\n' "$(cat "$d/name" 2>/dev/null)" "$(cat "$d/\${n}_label" 2>/dev/null)" "$f"
            done
            for f in /sys/class/drm/card*/device/gpu_busy_percent; do
              [ -r "$f" ] && printf 'gpu-busy\\t%s\\n' "$f"
            done
            for f in /sys/class/drm/card*/gt/gt0/rc6_residency_ms /sys/class/drm/card*/power/rc6_residency_ms; do
              [ -r "$f" ] && printf 'gpu-idle\\t%s\\n' "$f"
            done
            for d in /sys/class/drm/card*/device/tile*/gt*/gtidle; do
              case "$(cat "$d/name" 2>/dev/null)" in
                *-rc) [ -r "$d/idle_residency_ms" ] && printf 'gpu-idle\\t%s\\n' "$d/idle_residency_ms" ;;
              esac
            done
            command -v nvidia-smi >/dev/null 2>&1 && printf 'nvidia\\n'
            true`]
        stdout: StdioCollector {
            onStreamFinished: root.parseSensors(text)
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.parseMeminfo(text())
    }

    FileView {
        id: cpuTempFile
        path: root.cpuTempPath
        onLoaded: root.cpuTemp = Number(text()) / 1000
    }

    FileView {
        id: gpuTempFile
        path: root.sampleGpu ? root.gpuTempPath : ""
        onLoaded: root.gpuTemp = Number(text()) / 1000
    }

    FileView {
        id: gpuBusyFile
        path: root.sampleGpu ? root.gpuBusyPath : ""
        onLoaded: root.gpuUsage = Number(text()) / 100
    }

    FileView {
        id: gpuIdleFile
        path: root.sampleGpu ? root.intelIdlePath : ""
        onLoaded: root.parseGpuIdle(Number(text()), Date.now())
    }

    // "34, 61": utilization %, temperature °C. First GPU only.
    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [usage, temp] = text.split("\n")[0].split(",").map(Number);
                if (!isNaN(usage))
                    root.gpuUsage = usage / 100;
                if (!isNaN(temp))
                    root.gpuTemp = temp;
            }
        }
    }

    Timer {
        interval: root.interval
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (cpuTempFile.path !== "")
                cpuTempFile.reload();
            if (gpuTempFile.path !== "")
                gpuTempFile.reload();
            if (gpuBusyFile.path !== "")
                gpuBusyFile.reload();
            if (gpuIdleFile.path !== "")
                gpuIdleFile.reload();
            if (root.useNvidia && !nvidia.running)
                nvidia.running = true;
        }
    }
}
