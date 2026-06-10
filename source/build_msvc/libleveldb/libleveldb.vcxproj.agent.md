# libleveldb.vcxproj Agent Notes

## Purpose

Builds LevelDB for Windows chainstate/block index storage.

## Nu Risk

- LevelDB changes can affect chainstate safety, reindex behavior, and wallet startup reliability.

## Do Not Break

- Do not change storage engine source membership or compiler flags casually.
- Keep the build aligned with Core's expected LevelDB ABI and options.

## Verification

- `git diff --check`
- Windows build; run a disposable datadir startup/reindex smoke test after storage changes.
