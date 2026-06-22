# main.cpp Agent Notes

## Purpose

Initializes the Nu QML app, command-line switches, backend/service objects, single-instance guard, QML registrations, and launch-time debug behavior.

## Nu Divergence

- Adds single-instance lock handling with "check again" and "close other instance" flows.
- Translates Nu debug launch switches into environment/backend behavior for Core TCP sync, Core block-body sync, Fast Sync, and Quick Clone isolation tests.
- Supports Quick Clone launch initiation and Nu-only wallet startup behavior.
- Loads bundled Nu fonts from `Resources/nu/assets/fonts` before QML starts so
  Atkinson Hyperlegible Mono is available to QML and C++ paper-wallet rendering
  without depending on system font installs.
- Shows launch progress on the splash screen with one centered top status line so loading text does not collide with the logo/title artwork.
- Supports `--grab-splash <path>` as a focused diagnostic that writes the exact
  generated startup splash pixmap and exits before backend startup.
- The splash coin + wordmark lockup is drawn from the generated brand asset
  `defcoin-core-nu-lockup.png`, the same asset used by `NuBrandLockup.qml`. Do
  not recreate splash logo spacing with independent font math. Update
  `docs/brand-logo-text.md`, the generated lockup asset, and
  `NuBrandLockup.qml` together when ratios change.
- Provides an internal `--ui-self-test` route/dialog/menu walk. It disables
  backend autostart, skips the single-instance guard, opens Nu route surfaces,
  exercises menu-backed dialogs, and can capture screenshots via
  `DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS`.
- When `DEFCOIN_NU_PAPER_WALLET_PDF` is set during `--ui-self-test`, renders
  the paper-wallet print sheet with fake placeholder key data to the requested
  PDF path for visual verification.
- When `DEFCOIN_NU_PAPER_WALLET_RENDER_ONLY=1` is combined with
  `DEFCOIN_NU_PAPER_WALLET_PDF`, the self-test exits after rendering the paper
  wallet. Use this for fast paper-layout iteration without walking every route,
  menu, or dialog.
- When `DEFCOIN_NU_UI_SELF_TEST_PAPER_WALLET=1` is set, the Nu UI self-test
  captures the Wallet route with the Paper Wallet tab selected.
- When `DEFCOIN_NU_UI_SELF_TEST_SETTINGS_TAB=display` or `updates` is combined
  with `DEFCOIN_NU_UI_SELF_TEST_ROUTE=settings`, the self-test captures that
  Settings tab instead of the default Network tab.
- `DEFCOIN_NU_UI_SELF_TEST_ROUTE=<route>` narrows the self-test route walk to
  one route for focused layout debugging.

## Do Not Break

- Always re-check the lock after the user acknowledges a duplicate-instance warning; do not allow two Nu instances to use one datadir.
- Do not make debug isolation switches default behavior.
- Keep app bundle identity stable enough for macOS Local Network permission behavior and build testing.
- Keep bundled font loading early and non-fatal. Missing fonts may warn, but
  must not block startup or paper-wallet key safety behavior.
- Keep splash status text short; long wrapped splash text can collide with branding and makes slow startup look broken.
- Keep splash logo measurements grouped around the combined coin + wordmark
  width, not just the text width, so the lockup stays centered.
- Keep `--ui-self-test` inert for normal launches and avoid generating real
  wallet/private-key material in that path.
- Keep `DEFCOIN_NU_PAPER_WALLET_PDF` limited to UI self-test placeholder data;
  it must not silently print or export real user paper-wallet keys.
- Keep `DEFCOIN_NU_PAPER_WALLET_RENDER_ONLY` narrower than the normal
  `--ui-self-test`; it is a render helper, not a substitute for full UI
  regression checks.

## Verification

- `git diff --check`
- Launch with and without an existing Nu instance and confirm duplicate handling loops until the first instance is actually closed or the user quits.
- Run `--ui-self-test --allow-multiple` after route, menu, dialog, or
  paper-wallet surface changes.
- Use `--grab-splash <path>` when checking splash-only artwork changes without
  relying on macOS screen-recording permission.
