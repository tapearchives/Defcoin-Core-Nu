# Main.qml Agent Notes

## Purpose

Owns the top-level Nu QML window, global dialogs, menus, wallet selector helpers, keyboard actions, about/build notes, Quick Clone prompt wiring, and recovery/update dialogs.

## Nu Divergence

- Keeps Nu wallet-first while Explorer and Forensics live in the separate Explore app.
- Provides the visible build notes text, Local Network permission explanation, UDP Fast Sync description, and Quick Clone safety wording.
- Centralizes sensitive clipboard confirmation for recovery phrases and private key material.

## Do Not Break

- Keep Quick Clone warning text clear that wallets/private data are never copied.
- Keep sensitive clipboard flows guarded.
- Keep menu route names aligned with `AppFrame.qml` and service invokables.
- Do not make Advanced tools visible by default for new users unless that product decision changes.

## Verification

- `git diff --check`
- Launch Nu and check About/build notes, Quick Clone prompt, and global copy shortcuts after edits.
