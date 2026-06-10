# libunivalue.vcxproj Agent Notes

## Purpose

Builds UniValue JSON support for Windows RPC and config-facing code.

## Nu Risk

- RPC console, Fast Sync reservation RPC, and many backend RPCs depend on stable JSON parsing/serialization.

## Do Not Break

- Do not change UniValue source membership without RPC regression tests.
- Keep this target independent from Qt.

## Verification

- `git diff --check`
- Windows build; smoke-test JSON RPC commands after changes.
