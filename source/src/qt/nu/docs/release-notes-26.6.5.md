# Defcoin Core Nu 26.6.5 Release Notes

Date: 2026-06-10

## Developer Style Baseline

- Added and applied the Nu-local clang-format policy to the Tahoe Qt/QML bridge
  sources under `src/qt/nu`.
- The formatter scope is intentionally limited to Nu-owned C++, Objective-C++,
  and helper code so upstream Litecoin/Core formatting remains unchanged.
- The Nu style file now has both C++ and Objective-C sections, so `.cpp`,
  `.h`, and `.mm` files use the same readable line-breaking rules.
- Ruff was run against the Nu Python helper scripts; both currently pass without
  required source changes.

## DOX / Agent Notes

- Added a Nu tools DOX index and a companion note for the headless
  `defcoin_fast_syncd.py` Fast Sync responder.
- The responder note records the service-bit 29, responder-only, no-wallet-data,
  and checksum/probe assumptions needed by server and cross-platform builds.

## Build Identity

- Tahoe frontend and backend release labels now report `26.6.5`.
- This is a metadata/style baseline build. No intended wallet, consensus,
  Fast Sync, Quick Clone, or network behavior changes are introduced by the
  style pass.

## Tahoe Apple Silicon Build

- Built backend tools and verified `defcoind`, `defcoin-cli`, and
  `defcoin-wallet` report `v26.6.5`.
- Built Tahoe Qt/QML app in `build/nu-qml-arm64-26.6.5`.
- Staged Apple Silicon distribution:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5-20260610/apple-silicon/Defcoin Core Nu.app`
- Staged DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5-20260610/apple-silicon/Defcoin-Core-Nu-v26.6.5-macOS-AppleSilicon.dmg`
- Codesign deep verification passed. Gatekeeper `spctl` rejects the local build
  because it is ad-hoc signed and not Developer ID notarized.

## Porting Notes

- Lion should use the same policy idea, but keep Ruff rules conservative for
  legacy Python compatibility and avoid pyupgrade rules that could break OS X
  10.7-era runtimes.
- Windows and Catalina should inherit the `26.6.5` release label once their
  builds are refreshed from this source.
