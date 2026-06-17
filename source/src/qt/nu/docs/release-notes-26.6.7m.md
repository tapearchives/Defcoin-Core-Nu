# Defcoin Core Nu 26.6.7m Release Notes

Date: 2026-06-16

## Paper Wallet UI

- Refines the Paper Wallet entropy hourglass so the upper sand follows the glass chamber, drains from a flatter-to-slightly-concave surface, and avoids the previous hard V or rectangular source-sand shape.
- Adds denser, jittered falling-grain streams between the neck and lower mound so keyboard and pointer input visibly produce moving sand rather than a single static line.
- Gives the Sheet Preview more horizontal space and tighter internal margins so actual rendered print pages use the preview pane more effectively.

## Build And Crypto Dependency Check

- Verified Tahoe Homebrew OpenSSL is current at OpenSSL 3.6.2 and the staged 26.6.7l app bundle was already carrying `libcrypto.3.dylib` / `libssl.3.dylib` from OpenSSL 3.6.2.
- This build keeps the same OpenSSL 3.6.2 dependency path unless the packager intentionally pins a different OpenSSL formula.

## Notes For Lion And Windows Parity

- Port the QML hourglass math and preview-pane sizing changes to Lion and Windows. Keep the underlying paper-wallet print/preview renderer shared with C++ rather than introducing a separate platform-specific sheet sketch.
