# Defcoin Core Nu 26.6.1c Release Notes

Defcoin Core Nu `26.6.1c` is a packaging correction over `26.6.1b`. The
inherited Core client build number is unchanged.

## macOS Packaging

- Fixed Apple Silicon staging so Qt framework install names are rewritten to
  the bundled `Contents/Frameworks` copies before signing. This prevents
  launch-time crashes caused by loading both Homebrew Qt and bundled Qt.

## Diagnostics

- Carries the `26.6.1b` Peers table fix: LAN workstation names align left, while
  non-LAN seed and DNS source values align right.
- Carries the LAN workstation display cleanup that removes redundant source
  labels such as `WHISPER | NetBIOS: WHISPER`.
