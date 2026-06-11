# main.cpp Agent Notes

## Purpose

Initializes the Nu QML app, command-line switches, backend/service objects, single-instance guard, QML registrations, and launch-time debug behavior.

## Nu Divergence

- Adds single-instance lock handling with "check again" and "close other instance" flows.
- Translates Nu debug launch switches into environment/backend behavior for Core TCP sync, Core block-body sync, Fast Sync, and Quick Clone isolation tests.
- Supports Quick Clone launch initiation and Explorer/ExpFor split behavior.
- Shows launch progress on the splash screen with one centered top status line so loading text does not collide with the logo/title artwork.

## Do Not Break

- Always re-check the lock after the user acknowledges a duplicate-instance warning; do not allow two Nu instances to use one datadir.
- Do not make debug isolation switches default behavior.
- Keep app bundle identity stable enough for macOS Local Network permission behavior and build testing.
- Keep splash status text short; long wrapped splash text can collide with branding and makes slow startup look broken.

## Verification

- `git diff --check`
- Launch with and without an existing Nu instance and confirm duplicate handling loops until the first instance is actually closed or the user quits.
