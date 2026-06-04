# Cross-Build Internal Change Log

This file is the internal porting ledger for Defcoin Core Nu. Update it for
every Tahoe Nu build that changes behavior, build metadata, UI, backend
interfaces, packaging, or developer assumptions. It is not a user-facing release
note. Its audience is Codex, especially threads building the Lion Intel iMac,
Catalina UTM, Windows, and server variants.

## How To Use This File

For each new build:

1. Add a new version entry at the top of `Entries`.
2. Include the previous version it was based on.
3. Separate what must be ported from what is Tahoe-only.
4. Explain intent and hidden assumptions that a code diff will not reveal.
5. List exact files/functions when porting is likely non-obvious.
6. Include verification commands and the observed result.
7. Note whether Lion, Catalina, Windows, and server builds need equivalent work.

## Entry Template

```text
### <version> - <YYYY-MM-DD> - <short title>

Big picture:
- ...

Porting priority:
- Lion Intel:
- Catalina UTM:
- Windows:
- Server:

Changed behavior:
- ...

Changed files and important details:
- path: why it changed; what to port; what not to port.

Compatibility notes:
- ...

Build/package notes:
- ...

Verification performed:
- command/result

Risks / follow-up:
- ...
```

## Entries

### 26.6.4t - 2026-06-04 - LAN Fast Copy naming, Metrics row density, macOS bundle metadata

Big picture:
- This build separates three concepts that had drifted together in the UI:
  Fast Sync, LAN Fast Copy, and Quick Clone/DCOL.
- Fast Sync remains a transport-only path. It must not skip Core validation.
- LAN Fast Copy is the current online LAN block-copy mode. It pauses ordinary
  P2P on the receiver and requests checksum-protected block bytes from trusted
  LAN Nu peers, but still submits each block through Core acceptance.
- Quick Clone is now reserved as the human-friendly name for DCOL, a future
  trusted-LAN snapshot workflow intended to bypass historical validation by
  copying verified public chain state. Quick Clone/DCOL is not implemented in
  this build.
- The Metrics Status table now sizes one-line rows compactly while still
  allowing wrapped rows to grow.
- Apple Silicon macOS app bundles now stamp explicit macOS metadata to avoid
  System Information misclassifying builds.

Porting priority:
- Lion Intel: port the user-facing naming and docs concepts where the Lion UI
  exposes this setting. Do not rename backend internals mechanically unless the
  Lion source is already being touched for nearby reasons.
- Catalina UTM: port the naming, Metrics table row-height behavior if that UI
  exists, and the macOS bundle metadata pattern. Choose a deployment target that
  honestly matches the Qt libraries used by Catalina, not Tahoe's `26.0`.
- Windows: port naming and Metrics row-density behavior. The macOS plist work is
  not relevant.
- Server: no immediate code change from this entry. Server docs should preserve
  the same distinction: Fast Sync is transport-only; Quick Clone/DCOL is future
  snapshot copy.

Changed behavior:
- Settings no longer says `Quick Clone blocks from trusted LAN peers`; it says
  `LAN Fast Copy from trusted peers`.
- Metrics no longer labels the row `Quick Clone (LAN)`; it labels it `LAN Fast
  Copy`.
- Runtime status text now says LAN Fast Copy for the current validated LAN block
  transfer path.
- Quick Clone/DCOL is documented as future validation-bypass snapshot mode,
  limited to `blocks`, `chainstate`, and optional `indexes`; it must never copy
  wallets, keys, settings, peers, ban files, or RPC cookies.
- Metrics Status rows with one line of text no longer use the old fixed wrapped
  row height.

Changed files and important details:
- `source/src/clientversion.h`: visible backend/client label is `26.6.4t`.
- `source/src/qt/nu/app/NuRpcService.cpp` and `.h`: user-visible strings were
  renamed from Quick Clone to LAN Fast Copy. Internal member names such as
  `m_lan_quick_clone_status` intentionally remain for now to avoid a noisy
  refactor.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: checkbox text and hover help
  explain that LAN Fast Copy still uses Core acceptance and that Quick
  Clone/DCOL is future work.
- `source/src/qt/nu/qml/Components/NuDataTable.qml`: row height calculation now
  accepts row data and estimates wrapped text lines from column widths. This is
  why one-line Status rows shrink but long rows can still wrap.
- `source/src/qt/nu/qml/Views/NodeView.qml`: Status table sets
  `wrapBodyText: true`, `maxWrappedBodyLines: 3`, and `compact: true`.
- `source/src/qt/nu/docs/fast-sync-protocol.md`: now defines Fast Sync, LAN
  Fast Copy, and Quick Clone/DCOL as separate mechanisms.
- `source/src/qt/nu/docs/defcoin-core-nu-goals.md`: goal 8 was updated to keep
  those concepts distinct.
- `source/src/qt/nu/app/MacOSXBundleInfo.plist.in`: new explicit macOS plist
  template. It sets `CFBundleSupportedPlatforms=MacOSX`,
  `LSApplicationCategoryType=public.app-category.finance`, high-resolution
  capable flags, and `LSMinimumSystemVersion`.
- `source/src/qt/nu/app/CMakeLists.txt`: both Nu and Explore targets use the
  custom plist template. The default Tahoe deployment target is `26.0` because
  Homebrew Qt 6.11.1 on Tahoe has QtQuick frameworks stamped with `minos 26.0`.

Compatibility notes:
- The Tahoe default `CMAKE_OSX_DEPLOYMENT_TARGET=26.0` is correct for Tahoe's
  current Homebrew Qt package set, but it is not a universal recommendation.
  Lion and Catalina must use Qt libraries built for their target OS and set the
  deployment target to match those libraries.
- If a cross-build uses older Qt libraries with lower `minos`, it should pass an
  explicit `CMAKE_OSX_DEPLOYMENT_TARGET` for that platform instead of inheriting
  Tahoe's default.
- The macOS `Kind: iOS` concern should be investigated by checking plist keys
  and Mach-O load commands, not by guessing from Qt Creator alone:
  `CFBundleSupportedPlatforms`, `LSMinimumSystemVersion`, `LSRequiresIPhoneOS`,
  `UIDeviceFamily`, `DTPlatformName`, and `vtool -show-build`.

Build/package notes:
- Tahoe build directory used for verification:
  `build/nu-qml-arm64-26.6.4t`.
- Staged app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4t-20260604/Defcoin Core Nu.app`.
- Qt Creator was installed but no project-local `.user` kit file or saved kit
  config was found. The verified CMake cache/build metadata is the source of
  truth for this build.

Verification performed:
- Backend tools report `v26.6.4t`:
  `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.
- `git diff --check` passed before commit.
- Nu app smoke launch passed with `DEFCOIN_NU_NO_BACKEND_AUTOSTART=1` and
  `--smoke-test --route metrics`.
- Codesign verification passed:
  `codesign --verify --deep --strict --verbose=2`.
- Plist checks on the staged app showed:
  `CFBundleSupportedPlatforms=MacOSX`,
  `LSMinimumSystemVersion=26.0`,
  `CFBundlePackageType=APPL`,
  `CFBundleShortVersionString=26.6.4t`.
- Spotlight metadata showed:
  `kMDItemKind=Application`,
  `kMDItemCFBundleIdentifier=org.defcoincore.DefcoinCoreNu`,
  `kMDItemExecutableArchitectures=(arm64)`.
- `vtool -show-build` showed platform `MACOS` for app and bundled Qt binaries.
  No iOS-only plist keys were found.

Risks / follow-up:
- LAN Fast Copy still validates blocks, so it will not deliver the full speed
  gain expected from Quick Clone/DCOL. Implement DCOL later as a stopped-backend
  or coherent-snapshot copy of public chain state.
- The row-height calculation uses rough text-width estimation. If a future QML
  table uses unusual icons or custom delegates, verify row picking and scrolling.
- If future Homebrew Qt changes its deployment target again, rerun the plist and
  `vtool` checks rather than hard-coding assumptions.

