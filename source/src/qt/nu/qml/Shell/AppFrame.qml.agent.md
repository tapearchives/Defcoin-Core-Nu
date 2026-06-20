# AppFrame.qml Agent Notes

## Purpose

Owns the main Nu shell frame, route switching, left navigation placement, status strip area, and page loading.

## Nu Divergence

- Hides Advanced tools by default for new users while preserving advanced routes when enabled.
- Keeps wallet pages and advanced technical pages separated after Explorer/Forensics moved out.
- Guards route changes while Paper Wallet private keys remain in memory. The
  user must either return to Paper Wallet or accept key clearing before Nu
  switches routes.
- Exposes a self-test-only helper for opening Wallet > Paper Wallet so layout
  screenshots can be captured without manual navigation.

## Do Not Break

- Keep route IDs aligned with `Main.qml`, `NavigationRail.qml`, and view file names.
- Do not put Explorer/Forensics back into Nu unless explicitly requested; those belong in Explore/ExpFor.
- Preserve enough width for the navigation rail and status mast at common Mac/Lion window sizes.
- Do not route away from Wallet > Paper Wallet with generated keys silently
  alive; keep the warning/clear behavior synchronized with WalletView.
- Keep self-test route helpers limited to deterministic tab selection; they
  must not create wallets, change private-key state, or bypass Paper Wallet key
  clearing.

## Verification

- `git diff --check`
- Launch and switch through all visible routes with Advanced tools both off and on.
- Use `--ui-self-test` with the Settings tab environment hook after changing
  Settings tab routing.
