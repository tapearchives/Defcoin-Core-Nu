# Defcoin Core Nu 26.6.4t Release Notes

Defcoin Core Nu `26.6.4t` is a naming, documentation, Metrics table, and macOS
bundle metadata polish update over `26.6.4s`.

## Quick Clone / DCOL Naming

- Reserves `Quick Clone` as the human-friendly name for Direct Copy Over LAN
  (DCOL), the future trusted-LAN snapshot mode intended to bypass historical
  validation by copying verified chain state from a user-trusted machine.
- Renames the current online LAN block-copy setting to `LAN Fast Copy from
  trusted peers` so it is not confused with Quick Clone/DCOL.
- Updates LAN Fast Copy help text and Metrics text to state that the current
  online path still submits blocks through Core acceptance.
- Clarifies that a true Quick Clone/DCOL implementation must copy only public
  chain state such as `blocks`, `chainstate`, and optional `indexes`, never
  wallet material, and must use manifests, hashes, backend shutdown or coherent
  source snapshots, and post-copy verification choices.

## Metrics Status Table

- Fixes overly tall one-line Status rows by making wrapped table rows calculate
  their height from the actual text and column width.
- Keeps Metrics Status rows compact by default while still allowing genuinely
  wrapped values to grow up to three lines.

## macOS Bundle Metadata

- Stamps Apple Silicon app bundles with an explicit macOS deployment target
  instead of inheriting the host macOS version.
- Adds explicit `CFBundleSupportedPlatforms=MacOSX` metadata so macOS
  classifies the bundle as a normal macOS application.

## Version

- Updates the visible Nu release label to `26.6.4t`.
