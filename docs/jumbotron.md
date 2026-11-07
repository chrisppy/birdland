## Jumbotron pop-ups

Jumbotron shows a short pop-up on the focused monitor when the volume, the
microphone's mute or the screen brightness changes, whatever changed it. It
doesn't change anything itself, so bind your keys to the usual tools in your
Niri config, for example:

```kdl
XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+" "-l" "1.0"; }
XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
```

Brightness is read from `/sys/class/backlight`, so it shows on laptops and is
silent on desktop monitors.
