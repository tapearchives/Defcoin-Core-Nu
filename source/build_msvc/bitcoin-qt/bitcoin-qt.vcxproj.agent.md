# bitcoin-qt.vcxproj Agent Notes

## Purpose

Builds the classic Windows Qt wallet executable from the MSVC project graph.

## Nu Risk

- Depends on every major backend static library plus `libbitcoin_qt`.
- Inherits Qt static library settings from `common.qt.init.vcxproj`.
- This is not the Tahoe Nu QML app, but it may still be used for Windows parity or backend smoke builds.

## Do Not Break

- Keep project references complete; missing wallet/server/consensus references can produce misleading runtime failures.
- Do not confuse this target with the Nu QML packaging path unless explicitly integrating them.

## Verification

- `git diff --check`
- Windows Qt build and launch smoke test.
