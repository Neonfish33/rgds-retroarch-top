# RetroArch на верхний экран (RG DS / двухэкранные Android-консоли)

Небольшой root-сервис, который держит **RetroArch на втором (верхнем) экране** двухэкранной
Android-консоли (например **Anbernic RG DS**). Игры и остальные ретро-платформы через
RetroArch открываются сверху, а Daijishou/библиотека остаётся снизу.

> English version: [README.en.md](README.en.md)

## Зачем

Прошивка отдаёт нижний экран как основной (display 0), а верхний — как второй (display 2).
Обычное приложение не может само вывести окно на верхний экран (`am start --display` из
приложения игнорируется). Из-под root (shell) — может. Этот watcher ловит запуск RetroArch
и переносит уже загруженную игру на верхний экран.

## Требования

- Rooted (userdebug) Android с работающим `adb remount` (bootloader разлочен,
  dm-verity выключен — обычно `verifiedbootstate=orange`).
- Встроенный `su` (как на Anbernic).
- RetroArch aarch64 (`com.retroarch.aarch64`).

## Установка

```bash
./install.sh
# или вручную (Windows — те же команды через adb):
adb push ra_top.sh /data/local/tmp/ra_top.sh
adb shell su -c "chmod 755 /data/local/tmp/ra_top.sh"
adb root
adb remount
adb push ra_top.rc /system/etc/init/ra_top.rc
adb shell su -c "chown root:root /system/etc/init/ra_top.rc; chmod 644 /system/etc/init/ra_top.rc"
adb reboot
```

После перезагрузки проверь: `adb shell getprop init.svc.ra_top` → `running`.

## Настройка

Открой `ra_top.sh` и при необходимости поменяй:

- `DISPLAY_ID` — id экрана, куда выводить игры. На RG DS верхний = `2`.
  Узнать: `adb shell dumpsys display | grep -E 'displayId|DisplayDeviceInfo'`.
- `WAIT` — задержка перед переносом (дать игре загрузиться; перенос «на лету» сбивает загрузку рома).
- `PKG`/`ACT` — если у тебя другая сборка RetroArch (напр. `com.retroarch`).

После правки: `adb push ra_top.sh /data/local/tmp/` и `adb reboot` (или перезапусти сервис).

## Как это работает

- init-сервис `ra_top` запускается при `sys.boot_completed=1` и держит `ra_top.sh`;
- скрипт следит за pid RetroArch; при новом запуске ждёт `WAIT` сек и делает
  `am start --display <id> -n <activity>` — пустой intent уходит в уже запущенный
  экземпляр RetroArch, игра продолжается, но окно переезжает наверх;
- действует один раз на запуск процесса, во время игры не мешает.

## Удаление

```bash
adb root && adb remount
adb shell su -c "rm /system/etc/init/ra_top.rc; setprop ctl.stop ra_top; rm /data/local/tmp/ra_top.sh"
adb reboot
```

## Нюансы

- Наверх уходят **все** платформы RetroArch (аркады, NES, GBA и т.д.). Standalone-эмуляторы
  (DraStic, PPSSPP, Lime3DS) watcher не трогает — они открываются на нижнем экране.
- Изменения в `/system` идут через overlayfs (`adb remount`) и переживают перезагрузку;
  сбрасываются при factory reset.
- Первая игра после включения ~несколько секунд на нижнем экране, потом «прыгает» наверх.

## Лицензия

MIT.
