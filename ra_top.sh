#!/system/bin/sh
# Keeps RetroArch on the secondary (top) screen of a dual-screen Android handheld
# (e.g. Anbernic RG DS). Launched at boot by the ra_top init service (see ra_top.rc).
#
# On each new RetroArch process it reads the game RetroArch was asked to start
# ("auto-start game [<rom>]") and the core ("libretro path: [<core>]") from the log, then
# re-issues the launch on DISPLAY_ID. Relaunching with the real content -- instead of an
# empty intent to an already-running instance -- never cancels a slow-loading game (PS1),
# and it works every time because it is keyed on the process, not on the game path.
#
# Configure DISPLAY_ID: on the RG DS the top screen is 2 (bottom/main is 0). Find yours:
#   adb shell dumpsys display | grep -E 'displayId|DisplayDeviceInfo'

DISPLAY_ID=2
ACT=com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture
CFG=/storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg
PKG=com.retroarch.aarch64

prev=""
while true; do
  pid=$(/system/bin/pidof "$PKG" 2>/dev/null)
  if [ -n "$pid" ] && [ "$pid" != "$prev" ]; then
    /system/bin/sleep 2
    log=$(logcat -d -s RetroArch 2>/dev/null | tail -40)
    rom=$(echo "$log" | grep 'auto-start game' | tail -1 | sed -n 's/.*auto-start game \[\(.*\)\]$/\1/p')
    core=$(echo "$log" | grep 'libretro path' | tail -1 | sed -n 's/.*libretro path: \[\(.*\)\]$/\1/p')
    if [ -n "$rom" ] && [ -n "$core" ]; then
      /system/bin/am start --display "$DISPLAY_ID" -n "$ACT" \
        -e ROM "$rom" -e LIBRETRO "$core" -e CONFIGFILE "$CFG" >/dev/null 2>&1
    fi
  fi
  prev="$pid"
  /system/bin/sleep 1
done
