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
- `ACT`/`CFG` — активность и конфиг RetroArch (по умолчанию сборка aarch64).

После правки: `adb push ra_top.sh /data/local/tmp/` и `adb reboot` (или перезапусти сервис).

## Как это работает

- init-сервис `ra_top` запускается при `sys.boot_completed=1` и держит `ra_top.sh`;
- скрипт читает лог RetroArch (какую игру и на каком ядре он запускает —
  `auto-start game [...]`, `libretro path: [...]`) и **перезапускает эту же игру на
  `DISPLAY_ID`** через `am start --display`;
- так как запускается реальный контент (а не пустой intent в уже работающий экземпляр),
  медленные игры (PS1) не сбиваются;
- действует один раз на каждый новый запуск, во время игры не мешает.

## PS1 (и другие ядра с BIOS)

Для PS1-ядер (`swanstation`, `beetle_psx*`) нужен **BIOS** в системной папке RetroArch
(`/storage/emulated/0/RetroArch/system/`): напр. `scph1002.bin` (PAL) или `scph5501.bin`
(NTSC-U). Без BIOS игра не стартует. BIOS определяется по содержимому, но имя лучше дать
каноническое.

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
