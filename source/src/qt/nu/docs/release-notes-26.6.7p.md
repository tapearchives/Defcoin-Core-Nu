# Defcoin Core Nu 26.6.7p Release Notes

Internal Tahoe candidate focused on packaging hygiene for the Nu wallet bundle.

## Packaging

- Stops shipping source-only QML `.agent.md` companion notes inside the Nu app
  bundle.
- Stops shipping non-wallet QML screens inside the Nu wallet bundle.
- Removes generated Finder/Python/Ruff cache files from the active Nu source
  tree.
- Removes the stale paper-wallet hourglass PNG left behind after the entropy
  hourglass animation was removed.

## Verification

- Rebuilt Tahoe backend tools; bundled `defcoind`, `defcoin-cli`,
  `defcoin-tx`, and `defcoin-wallet` report `26.6.7p`.
- Built Tahoe Apple Silicon Nu resources in `source/build/nu-qml-arm64-26.6.7p`.
- Staged the checked app at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.7p-20260617/apple-silicon/`.
- Verified the staged Nu bundle no longer contains `.agent.md` files,
  non-wallet QML screens, `.DS_Store` files, or the stale hourglass PNG.
- Verified the staged bundle reports `26.6.7p` and passes
  `codesign --verify --strict --deep`.
