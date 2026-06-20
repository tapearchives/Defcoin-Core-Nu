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
- Provides `uiSelfTestOpenSettingsTab()` so focused screenshots can cover
  Settings > Display and Settings > Updates without manual clicks.
- Shows the shutdown overlay while Nu starts service cleanup. The overlay text
  should surface `NuService.shutdownStatus` so users understand which backend
  process or helper is still closing.
- The Create Wallet dialog owns passphrase visibility/status feedback and the
  optional BIP39 phrase generation subform. It must preserve user-entered fields
  across async backend create failures and reset only after a successful wallet
  create or user cancel. When encryption is enabled, passphrases default hidden;
  generated BIP39 words must be visible from the dialog state until the dialog
  resets.
- Restore Wallet exposes zero-balance skipping only for fixed address-count
  scans. The UI must explain that this checks current balances, does not recover
  addresses with only fully spent historical activity, and can use a current Nu
  Explore index for faster lookup before falling back to Core's UTXO scan.
  Recovery progress must keep address scan status, elapsed time, and ETA visible
  after restore starts.
- Restore Wallet exposes an opt-in SQL descriptor wallet checkbox that defaults
  off. When enabled, the UI must keep zero-balance skip unavailable and avoid
  auto-until-empty scans because the backend imports ranged descriptors.

## Do Not Break

- Keep Quick Clone warning text clear that wallets/private data are never copied.
- Keep sensitive clipboard flows guarded.
- Keep menu route names aligned with `AppFrame.qml` and service invokables.
- Menu and shortcut route changes must call `AppFrame.requestRoute()` so the Paper Wallet private-key leave guard is not bypassed.
- Do not make Advanced tools visible by default for new users unless that product decision changes.
- Keep UI self-test hooks deterministic. The legacy `create-recovery-wallet`
  hook may open the combined Create Wallet dialog with the BIP39 option
  selected, but it must not submit or create wallets.
- Keep shutdown overlay behavior wired to `NuService.prepareForApplicationQuit()`
  before calling the platform quit path.
- Do not clear Create Wallet fields from `onClosed` while a createwallet RPC is
  pending; the backend completion signal decides whether to reset or reopen.
- Do not enable the restore zero-balance skip checkbox for auto-until-empty
  scans; that mode imports/rescans batches before it can observe address use.
- Do not enable restore zero-balance skip while SQL descriptor wallet recovery is
  selected; SQL restore imports wallet descriptors rather than individual
  pre-filtered legacy address ranges.
- Do not hide the Nu Explore suggestion when zero-balance skip is selected; it
  is the user's pre-start cue to refresh the local index for faster safe
  lookups.

## Verification

- `git diff --check`
- Launch Nu and check About/build notes, Quick Clone prompt, and global copy shortcuts after edits.
- Run Nu `--ui-self-test --allow-multiple` after global menu/dialog changes.
