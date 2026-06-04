# Defcoin Core Nu 26.6.4w Release Notes

## Summary

This build is a GUI polish pass over shared controls. It improves interaction
feedback without changing wallet, RPC, network, Fast Sync, or Quick Clone
behavior.

## Changes

- Buttons now have subtle press motion, animated focus/hover states, and clearer
  active affordance.
- Left navigation items now press more cleanly and animate hover/focus colors.
- Combo boxes can be opened from the arrow/indicator area and support
  Return/Enter/Space popup toggling.
- Tabs now have a more polished selected state and smoother hover/focus changes.
- Text fields animate focus and hover borders.
- Metric rows now have subtle hover surfaces, making status/tooltips easier to
  discover in dense masthead and Metrics layouts.

## Safety Boundary

This is a QML/interface-only polish release. It does not change wallet storage,
private key handling, RPC parsing, block validation, Fast Sync negotiation, or
Quick Clone/DCOL protocol behavior.

## Packaging Note

The Apple Silicon app bundles were republished after the full resource bundle
target was run. The repaired apps include the splash/logo assets, QML payload,
bundled backend tools, and Qt runtime files; the earlier binary-only copy could
show a logo-less splash and exit immediately.
