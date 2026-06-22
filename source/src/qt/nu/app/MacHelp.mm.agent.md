# MacHelp.mm Agent Notes

## Purpose

Implements macOS native launch-state cleanup, app activation, and Help Book registration/opening through AppKit/Carbon APIs.

## Nu Risk

- Bridges Objective-C++ and Qt. Small memory/lifetime mistakes can break Help menu behavior or app launch on macOS.
- Launch cleanup clears both the normal Library saved-state directory and the
  temporary ignored saved-state directory before Qt starts, then activation can
  unhide `NSApp` after Qt creates the main window.

## Do Not Break

- Keep help book title/folder aligned with Info.plist helper scripts.
- Keep Objective-C objects scoped safely; avoid storing raw Cocoa objects in Qt-owned long-lived state unless retained correctly.
- Do not make missing help content fatal; help may be disabled in some builds.

## Verification

- `git diff --check`
- macOS build; open a known help page from Nu.
