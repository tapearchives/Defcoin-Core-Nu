# Nu Tools DOX

## Purpose

This folder contains local launch gates, test helpers, and protocol support tools used around the Nu desktop app and server-side Fast Sync testing.

## Local Contracts

- Tooling must never write wallet secrets, private keys, RPC cookies, or passphrases to logs.
- Launch/test helpers should make macOS Local Network permission, duplicate-instance, and crash-dialog gates explicit before interpreting UDP results.
- If a crash dialog is visibly blocking the screen but `System Events` cannot
  see it, use the visible-button OCR helper and require exact context text
  before clicking.
- Server-side tools may share Fast Sync transport behavior, but they must not depend on QML or desktop-only classes.
- Keep output stable enough for shell scripts and cross-build notes to parse.

## Work Guidance

- Prefer narrow command-line flags over hidden environment behavior.
- Keep compatibility with the Python runtime used by the target host; avoid syntax upgrades that would break older deployment hosts.
- If a script has a sibling `[full filename].agent.md`, read that companion before editing the script and keep it current with durable behavior changes.

## Verification

- `ruff check` for Python tools where the target runtime supports the configured rules.
- Run the script in dry-run/help mode after argument-parser changes.
- For Fast Sync tools, verify capability negotiation, allowlist refresh, packet parsing, checksum, and responder logs against a live or mocked backend.

## Child DOX Index

- `defcoin_fast_syncd.py` - headless UDP Fast Sync responder for server/LAN testing.
- `macos_click_visible_button.sh` - OCR fallback for exact visible system-dialog
  button clicks, used by crash-dialog launch gates.
- `nu_test_launch_gate.sh` - launch guard used by Nu test runs.
