# Defcoin Core Nu 26.6.4bq

## Fast Sync

- Fixed the UDP Fast Sync-only direct reservation path so `reservefastsyncblock
  reserve` sends the requested block height as a string. The backend RPC help
  and parser treat the optional third argument as `height_or_hash`; sending a
  JSON number caused `JSON value is not a string as expected` and put UDP into
  cooldown during isolated Fast Sync tests.
- Hardened `reservefastsyncblock` to accept either string or numeric JSON for
  the optional height/hash parameter by using `getValStr()`. This preserves CLI
  behavior and prevents future frontend JSON type mismatches from blocking UDP
  block reservations.

## Cross-Build Notes

- Lion legacy UI must make the equivalent change in
  `src/qt/nu/legacy-osx107/main.cpp`: when `directLanReservation` is true,
  push `QString::number(wantedHeight)` instead of the raw integer.
