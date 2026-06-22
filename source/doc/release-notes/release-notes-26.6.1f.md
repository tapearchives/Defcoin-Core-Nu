# Defcoin Core Nu 26.6.1f Release Notes

Defcoin Core Nu `26.6.1f` is a small documentation and wording cleanup over
`26.6.1e`.

## Changes

- Clarified About/header wording from `Backend: Litecoin Core v0.21.5.5 + Defcoin
  parameters` to `Backend originated from Litecoin Core v0.21.5.5 + Defcoin
  parameters` so users do not confuse the inherited Core baseline with the
  visible Nu package release.
- Added `initial-launch-crash-prevention.md`, a dedicated developer note for
  recurring first-launch crashes. It documents confirmed recent causes, including
  mixed Homebrew/bundled Qt frameworks, missing Qt platform/runtime plugins,
  bundle identity drift, saved-window restoration confusion, stale backend
  instances, and dirty Nu split worktrees.
- Linked the launch-crash prevention note from the Nu developer docs index.

The inherited Core client compatibility version is unchanged.
