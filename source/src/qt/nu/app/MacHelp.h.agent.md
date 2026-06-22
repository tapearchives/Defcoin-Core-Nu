# MacHelp.h Agent Notes

## Purpose

Declares the macOS native launch-state, activation, and help-book opening helpers.

## Nu Risk

- Exposes a small platform bridge used by app startup, `NuRpcService`, and QML help actions.

## Do Not Break

- Keep the API small and Qt-friendly.
- If the function name or signature changes, update `MacHelp.mm` and all call sites.

## Verification

- `git diff --check`
- macOS build and Help menu/manual smoke test.
