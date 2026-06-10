# fix_macos_qt_rpath.sh Agent Notes

## Purpose

Small rpath cleanup helper for macOS app binaries after Qt deployment.

## Nu Risk

- Incorrect rpaths can make the app depend on Homebrew paths or fail on another Mac.

## Do Not Break

- Keep `@executable_path/../Frameworks` as the app-local runtime path.
- Do not delete unrelated rpaths unless the packaging validation proves they are unsafe.

## Verification

- `git diff --check`
- `otool -l` and `otool -L` on the packaged app binary.
