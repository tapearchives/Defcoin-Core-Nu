# Defcoin Core Nu 26.6.4a Release Notes

Defcoin Core Nu `26.6.4a` is a Fast Sync protocol and Python tooling update
over `26.6.3l`.

## Fast Sync Protocol Cleanup

- Keeps the simplified Fast Sync design explicit: Core's normal peer/block
  scheduling reserves the block first, and UDP only transports that exact
  reserved block body.
- Removes stale transition wording that implied User-Agent fallback behavior.
  Fast Sync capability is now described as service-bit driven through
  `NODE_DEFCOIN_FASTSYNC`.
- Renames the headless sidecar's allowlist/log language so ignored UDP packets
  are reported as missing a connected Fast Sync service-bit peer, not as a
  generic Nu/User-Agent mismatch.

## Python Tooling

- Adds a Ruff configuration for the Nu source tree.
- Adds VS Code-compatible on-save settings for Ruff formatting and safe fixes
  on Python files.
- Applies `ruff check --fix` and `ruff format` to the Nu Fast Sync sidecar and
  macOS bundle-repair helper.
