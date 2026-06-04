# Defcoin Core Nu 26.6.4v Release Notes

## Summary

This build tightens the Quick Clone user warning and documents the receiver-side
copy scheduler that will be used by the trusted LAN snapshot workflow.

## Changes

- Added a warning dialog before the manual `Sync using Quick Clone now` action.
- Updated the automatic Quick Clone prompt to state that partial clones are not
  usable chain state.
- Documented the Quick Clone/DCOL receiver scheduler:
  - receiver controls all requests;
  - seed each compatible LAN source with two ranges;
  - request one more range only after the prior range passes its streaming
    checksum;
  - retry timed-out or bad ranges from another compatible source;
  - send best-effort cancels for stale requests.
- Documented the speed-first checksum rule: Quick Clone should use one
  deterministic streaming checksum family, updated while bytes are already being
  read and written, with no paranoid mode in the UI.

## Safety Boundary

Quick Clone still does not install copied chainstate in this build. Final live
replacement remains blocked until immutable source manifests, staging
verification, and receiver backend stop/swap/restart are implemented.

