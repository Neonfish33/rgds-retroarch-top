#!/system/bin/sh
# Keeps RetroArch on the secondary (top) screen of a dual-screen Android handheld
# (e.g. Anbernic RG DS). Launched at boot by the ra_top init service (see ra_top.rc).
#
# RetroArch logs the game it was asked to start ("auto-start game [<rom>]") and the core
# ("libretro path: [<core>]"); this script picks those up and re-issues the launch on
# DISPLAY_ID. Relaunching with the real content -- instead of an empty intent to an
# already-running instance -- never cancels a slow-loading game (PS1 in particular).
#
# Configure:
#   DISPLAY_ID - display id to show games on. On the RG DS the top screen is 2
#                (the bottom/main one is 0). Find yours with:
#                    adb shell dumpsys display | grep -E 'displayId|DisplayDeviceInfo'
#   ACT, CFG   - RetroArch activity / config path (aarch64 build by default).

DISPLAY_ID=2
ACT=com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture
CFG=/storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg

last=""
while true; do
  log=$(logcat -d -t 200 -s RetroArch 2>/dev/null)
  rom=$(echo "$log" | grep 'auto-start game' | tail -1 | sed -n 's/.*auto-start game \[\(.*\)\]$/\1/p')
  core=$(echo "$log" | grep 'libretro path' | tail -1 | sed -n 's/.*libretro path: \[\(.*\)\]$/\1/p')
  if [ -n "$rom" ] && [ "$rom" != "$last" ] && [ -n "$core" ]; then
    last="$rom"
    /system/bin/sleep 1
    /system/bin/am start --display "$DISPLAY_ID" -n "$ACT" \
      -e ROM "$rom" -e LIBRETRO "$core" -e CONFIGFILE "$CFG" >/dev/null 2>&1
  fi
  /system/bin/sleep 1
done
