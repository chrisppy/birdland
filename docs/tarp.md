## Tarp lock screen

Tarp runs in the background as a user service and locks every monitor when
asked; your password unlocks it. With `tarp.swayidle` (the default) it locks
after `lockAfter` minutes without input, before the machine sleeps, and on
`loginctl lock-session`. Before sleep, the lock command waits until Niri
confirms every monitor is covered, so the desktop never shows on resume. To lock
from a Niri keybind:

```kdl
Mod+Alt+L { spawn "birdland-tarp" "ipc" "call" "tarp" "lock"; }
```

The password is checked by PAM's `login` service, which exists on every NixOS
system and includes fingerprint login if you've enabled it there. To use a
dedicated service, add `security.pam.services.birdland-tarp = { };` to your
NixOS configuration and set `tarp.pamService = "birdland-tarp";`.

With `screenOffAfter` (15 minutes by default) the monitors also turn off when
idle; any input turns them back on. This uses swayidle too, so it needs
`tarp.swayidle`.

If Tarp crashes while locked, Niri keeps the screens locked (a solid color).
systemd restarts Tarp, which notices and locks again, so you can unlock as
usual. If it doesn't come back, switch to a text console (Ctrl+Alt+F2), log in,
and run `systemctl --user restart tarp`.
