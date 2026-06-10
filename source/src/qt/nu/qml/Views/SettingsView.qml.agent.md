# SettingsView.qml Agent Notes

## Purpose

Owns Settings tabs, network/connectivity controls, Quick Clone controls, display/table preferences, and updater preferences.

## Nu Divergence

- Connectivity contains LAN discovery, UDP Fast Sync, and Quick Clone/DCOL controls.
- Quick Clone is Advanced and trusted-LAN only; it prompts before arming user-requested clone activity.
- Display preferences include table width reset and copy delimiter behavior.

## Do Not Break

- Metrics must remain read-only; controls belong here or in a dedicated tool page.
- Quick Clone wording must keep the trust boundary explicit: public chain data only, never wallet/private/config data.
- LAN discovery permission text must not imply UDP Fast Sync over the public internet depends on LAN broadcast permission.

## Verification

- `git diff --check`
- Open Settings > Connectivity and Settings > Display; verify controls bind to `NuService` and do not clip.
