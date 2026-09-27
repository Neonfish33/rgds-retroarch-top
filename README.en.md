# RetroArch on the top screen (RG DS / dual-screen Android handhelds)

A tiny root service that keeps **RetroArch on the secondary (top) screen** of a dual-screen
Android handheld (e.g. **Anbernic RG DS**). RetroArch games and platforms show up on the top
screen while Daijishou / the library stays on the bottom.

> Русская версия: [README.md](README.md)

## Why

The stock firmware treats the bottom panel as the primary display (display 0) and the top
panel as a secondary display (display 2). A normal app cannot put its window on the secondary
display (`am start --display` from an app uid is ignored); from root (shell) it works. This
watcher detects RetroArch starting and moves the already-loaded game to the top screen.

## Requirements

- Rooted (userdebug) Android where `adb remount` works (unlocked bootloader, dm-verity
  disabled — usually `verifiedbootstate=orange`).
- A built-in `su` (as on Anbernic devices).
- RetroArch aarch64 (`com.retroarch.aarch64`).

## Install

```bash
./install.sh
# or manually (same commands via adb on Windows):
adb push ra_top.sh /data/local/tmp/ra_top.sh
adb shell su -c "chmod 755 /data/local/tmp/ra_top.sh"
adb root
adb remount
adb push ra_top.rc /system/etc/init/ra_top.rc
adb shell su -c "chown root:root /system/etc/init/ra_top.rc; chmod 644 /system/etc/init/ra_top.rc"
adb reboot
```

After reboot verify: `adb shell getprop init.svc.ra_top` → `running`.

## Configuration

Edit `ra_top.sh` if needed:

- `DISPLAY_ID` — the display to send games to. On the RG DS the top screen is `2`.
  Find yours: `adb shell dumpsys display | grep -E 'displayId|DisplayDeviceInfo'`.
- `WAIT` — seconds to wait before moving (let the game load; moving too early cancels the
  ROM load).
- `PKG`/`ACT` — for a different RetroArch build (e.g. `com.retroarch`).

After editing: `adb push ra_top.sh /data/local/tmp/` and `adb reboot` (or restart the service).

## How it works

- the `ra_top` init service starts at `sys.boot_completed=1` and runs `ra_top.sh`;
- the script watches RetroArch's pid; on a new launch it waits `WAIT` seconds and runs
  `am start --display <id> -n <activity>` — the empty intent is delivered to the already
  running RetroArch instance, so the game keeps playing but the window relocates to the top;
- it acts once per process start and never interferes while you play.

## Uninstall

```bash
adb root && adb remount
adb shell su -c "rm /system/etc/init/ra_top.rc; setprop ctl.stop ra_top; rm /data/local/tmp/ra_top.sh"
adb reboot
```

## Notes

- **All** RetroArch platforms move to the top (arcades, NES, GBA, ...). Standalone emulators
  (DraStic, PPSSPP, Lime3DS) are not touched and open on the bottom screen.
- Changes to `/system` go through overlayfs (`adb remount`) and survive reboot; they are
  cleared by a factory reset.
- The first game after boot shows on the bottom for a few seconds, then jumps to the top.

## License

MIT.
