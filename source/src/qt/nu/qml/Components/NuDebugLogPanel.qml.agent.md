# NuDebugLogPanel.qml Agent Notes

## Purpose

Reusable Debug Log panel restored from the earlier Metrics log surface. It owns
log verbosity, filter presets, search, line-number controls, font sizing, copy,
save, open-log, and selectable output.

## Nu Divergence

- Hosted under RPC Console as a Debug Log tab while continuing to use
  `NuRpcService` backend log APIs and line-number data.
- Mirrors the previous working Debug Log behavior as closely as possible; avoid
  redesigning this component when only the tab location changes.

## Do Not Break

- Keep log output selectable and copyable.
- Keep line-number controls and search/filter behavior wired to `NuService`.
- Do not expose private key, passphrase, or wallet-secret material in log UI.

## Verification

- `git diff --check`
- Open RPC Console > Debug Log and check filtering, copy, save/open actions,
  line-number display, and font-size controls.
