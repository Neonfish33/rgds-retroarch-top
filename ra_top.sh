#!/system/bin/sh
# Keeps RetroArch on the secondary (top) screen of a dual-screen Android handheld
# (e.g. Anbernic RG DS). Launched at boot by the ra_top init service (see ra_top.rc).
#
# When a new RetroArch process appears it waits a moment for the game to load, then moves
# the running instance to the chosen display with `am start --display <id>`. The empty
# intent is delivered to the already-running, single-task RetroArch activity, so the game
# keeps playing -- it just relocates. It only acts once per process start, so it never
# interferes while you play.
#
# Configure:
#   DISPLAY_ID  - the display id of the screen games should appear on. On the RG DS the
#                 top screen is 2 (the bottom/main one is 0). Find yours with:
#                     adb shell dumpsys display | grep -E 'DisplayDeviceInfo|displayId'
#   WAIT        - seconds to wait after launch before moving (let the game load first;
#                 moving too early cancels the ROM load).
#   PKG/ACT     - emulator package/activity. Default is RetroArch aarch64.

DISPLAY_ID=2
WAIT=7
PKG=com.retroarch.aarch64
ACT=com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture

prev=""
while true; do
  pid=$(/system/bin/pidof "$PKG" 2>/dev/null)
  if [ -n "$pid" ] && [ "$pid" != "$prev" ]; then
    /system/bin/sleep "$WAIT"
    /system/bin/am start --display "$DISPLAY_ID" -n "$ACT" >/dev/null 2>&1
  fi
  prev="$pid"
  /system/bin/sleep 1
done
