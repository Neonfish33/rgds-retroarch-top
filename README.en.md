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
- `ACT`/`CFG` — RetroArch activity and config path (aarch64 build by default).

After editing: `adb push ra_top.sh /data/local/tmp/` and `adb reboot` (or restart the service).

## How it works

- the `ra_top` init service starts at `sys.boot_completed=1` and runs `ra_top.sh`;
- the script reads RetroArch's log (which game and core it is starting —
  `auto-start game [...]`, `libretro path: [...]`) and **relaunches that same game on
  `DISPLAY_ID`** via `am start --display`;
- because it starts the real content (instead of sending an empty intent to an already
  running instance), slow-loading games (PS1) are not cancelled;
- it acts once per launch and never interferes while you play.

## PS1 (and other cores that need a BIOS)

PS1 cores (`swanstation`, `beetle_psx*`) need a **BIOS** in RetroArch's system directory
(`/storage/emulated/0/RetroArch/system/`): e.g. `scph1002.bin` (PAL) or `scph5501.bin`
(NTSC-U). Without a BIOS the game will not start. The BIOS is identified by content, but a
canonical filename is recommended.

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
