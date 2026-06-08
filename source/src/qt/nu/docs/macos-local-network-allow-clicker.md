# macOS Local Network Allow Clicker

`source/src/qt/nu/tools/macos_click_lan_allow.sh` is a test-only helper for
automating the macOS Local Network privacy prompt during Defcoin Core Nu LAN
testing.

It does one narrow job:

- screenshot every active display with `/usr/sbin/screencapture`;
- run Apple Vision OCR on the screenshot PNGs;
- require Local Network prompt context by default;
- find an exact `Allow` OCR match;
- click the center of the detected text with Quartz mouse events;
- return JSON and a deterministic exit code.

It deliberately avoids broad UI automation. The default context check prevents
the helper from clicking an unrelated `Allow` button in another app.

## Usage

```sh
source/src/qt/nu/tools/macos_click_lan_allow.sh --timeout 45
```

The timeout can also be passed as a positional value:

```sh
source/src/qt/nu/tools/macos_click_lan_allow.sh 45
```

By default the helper screenshots again every 6 seconds until the timeout
expires. Override that only when a test needs tighter polling:

```sh
source/src/qt/nu/tools/macos_click_lan_allow.sh --timeout 60 --interval 3
```

To debug OCR behavior, keep the latest screenshot:

```sh
source/src/qt/nu/tools/macos_click_lan_allow.sh --timeout 10 --save-last-screenshot /tmp/defcoin-lan-prompt.png
```

## Result Contract

Success prints JSON like:

```json
{"attempts":1,"confidence":0.98,"contextFound":true,"display":1,"elapsedSeconds":0.44,"ok":true,"status":"clicked","text":"Allow","x":1374.5,"y":624.0}
```

Failure prints JSON with `ok:false` and exits non-zero.

Exit codes:

- `0`: `Allow` was found and clicked.
- `1`: no matching `Allow` button was found before timeout.
- `2`: invalid arguments.
- `3`: screenshot or OCR failed.
- `4`: required macOS Screen Recording or Accessibility permission is missing.

## Permissions

The process running this helper needs:

- Screen Recording, because the helper captures the display through
  `screencapture`;
- Accessibility, because the helper posts a mouse click.

In the Codex desktop workflow those permissions usually belong to the terminal
or Codex host app that launches the script. If either permission is missing, the
helper fails with JSON instead of hanging.

## Defcoin Core Nu LAN Test Pattern

Launch the app or test that is expected to trigger the Local Network prompt,
then call the helper while the prompt is visible or expected to appear:

```sh
open -n "/path/to/Defcoin Core Nu.app"
source/src/qt/nu/tools/macos_click_lan_allow.sh --timeout 60
```

For Tahoe Fast Sync or Quick Clone testing this is a hard gate. If a newly
built Tahoe app shows the macOS Local Network prompt and the prompt is not
accepted, any LAN UDP result from that run must be treated as invalid. That run
only proves macOS privacy blocked the transport; it does not prove the UDP Fast
Sync or Quick Clone protocol failed.

For protocol-level checks, this pairs with
`source/src/qt/nu/tools/udp_lan_permission_gate.sh`: the gate watches Defcoin
logs for UDP activity, while this helper handles the macOS consent dialog.

On the Tahoe Mac mini the active Defcoin datadir is commonly:

```sh
/Volumes/TB5_4TB/d/Library/Application Support/Defcoin
```

The UDP gate watches that path as well as the default home-library datadir. If a
test uses another datadir, pass it explicitly:

```sh
DEFCOIN_DATADIR="/path/to/datadir" source/src/qt/nu/tools/udp_lan_permission_gate.sh --timeout 60
```
