# SettingsView.qml Agent Notes

## Purpose

Owns Settings tabs, network/connectivity controls, Quick Clone controls, display/table preferences, and updater preferences.

## Nu Divergence

- Connectivity contains LAN discovery, UDP Fast Sync, and Quick Clone/DCOL controls.
- Quick Clone is Advanced and trusted-LAN only; it prompts before arming user-requested clone activity.
- Display preferences include table width reset, copy delimiter behavior, the
  blockchain explorer preset selector, and separate custom transaction/address
  URL templates.
- The scheduled Defcoin-only magic setting label is August 1, 2026, matching
  service-side enforcement.

## Do Not Break

- Metrics must remain read-only; controls belong here or in a dedicated tool page.
- Quick Clone wording must keep the trust boundary explicit: public chain data only, never wallet/private/config data.
- LAN discovery permission text must not imply UDP Fast Sync over the public internet depends on LAN broadcast permission.
- Do not collapse custom explorer transaction and address templates into one
  field; explorers can require different path prefixes.

## Verification

- `git diff --check`
- Open Settings > Network and Settings > Display; verify controls bind to `NuService` and do not clip.
