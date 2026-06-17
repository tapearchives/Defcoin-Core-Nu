# Main.qml Agent Notes

## Purpose

Owns the top-level Nu QML window, global dialogs, menus, wallet selector helpers, keyboard actions, about/build notes, Quick Clone prompt wiring, and recovery/update dialogs.

## Nu Divergence

- Keeps Nu wallet-first while Explorer and Forensics live in the separate Explore app.
- Provides the visible build notes text, Local Network permission explanation, UDP Fast Sync description, and Quick Clone safety wording.
- Centralizes sensitive clipboard confirmation for recovery phrases and private key material.
- Provides internal `uiSelfTestOpenMenuDialog()` and
  `uiSelfTestClosePopups()` hooks so the C++ self-test can exercise
  menu-backed dialogs without relying on manual clicks.
- Provides `uiSelfTestOpenPaperWalletTab()` so the C++ self-test can capture
  the Wallet > Paper Wallet surface directly.
- Shows the shutdown overlay while Nu starts service cleanup. The overlay text
  should surface `NuService.shutdownStatus` so users understand which backend
  process or helper is still closing.

## Do Not Break

- Keep Quick Clone warning text clear that wallets/private data are never copied.
- Keep sensitive clipboard flows guarded.
- Keep menu route names aligned with `AppFrame.qml` and service invokables.
- Menu and shortcut route changes must call `AppFrame.requestRoute()` so the Paper Wallet private-key leave guard is not bypassed.
- Do not make Advanced tools visible by default for new users unless that product decision changes.
- Keep UI self-test hooks deterministic and free of real wallet/private-key
  generation.
- Keep shutdown overlay behavior wired to `NuService.prepareForApplicationQuit()`
  before calling the platform quit path.

## Verification

- `git diff --check`
- Launch Nu and check About/build notes, Quick Clone prompt, and global copy shortcuts after edits.
- Run Nu `--ui-self-test --allow-multiple` after global menu/dialog changes.
