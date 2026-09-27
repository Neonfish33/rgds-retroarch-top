#!/usr/bin/env bash
# Installs the RetroArch top-screen watcher on a rooted (userdebug) dual-screen Android
# handheld. Requires: adb, unlocked bootloader with dm-verity disabled ("adb remount"
# must work, e.g. verifiedbootstate=orange), and the built-in `su`.
#
#   ./install.sh            # uses `adb`
#   ADB="/path/to/adb" ./install.sh
set -e

ADB="${ADB:-adb}"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "==> pushing watcher script"
"$ADB" push "$HERE/ra_top.sh" /data/local/tmp/ra_top.sh
"$ADB" shell su -c "chmod 755 /data/local/tmp/ra_top.sh"

echo "==> remounting /system (overlayfs)"
"$ADB" root || true
"$ADB" remount

echo "==> installing init service"
"$ADB" push "$HERE/ra_top.rc" /system/etc/init/ra_top.rc
"$ADB" shell su -c "chown root:root /system/etc/init/ra_top.rc; chmod 644 /system/etc/init/ra_top.rc"

echo "==> done. Rebooting is required for the service to be picked up."
echo "    (adb reboot)"
