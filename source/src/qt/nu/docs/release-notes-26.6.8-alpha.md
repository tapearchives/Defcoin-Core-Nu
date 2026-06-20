# Defcoin Core Nu 26.6.8-alpha Release Notes

Alpha release candidate after the public GitHub `v26.3.1` release.

## Scope

This alpha rolls up the Tahoe/Nu work that accumulated through the local
`26.6.7` candidate series and promotes the next patch line to
`26.6.8-alpha`. It is intended for focused release testing before deciding
whether the strict public `26.6.8` line is ready.

## Highlights

- Adds and hardens the modern Nu wallet workflows: Wallets management, recovery
  phrase creation/restore, optional SQL descriptor recovery, passphrase quality
  feedback, passphrase visibility controls, wallet stats columns, watch-only
  address tooling, message-signing guidance, selectable inspection text, and a
  restored Debug Log surface.
- Adds the Paper Wallet workflow with local key/address derivation, BIP38
  handling, print/preview controls, Atkinson Hyperlegible Mono key rendering,
  entropy safeguards, and release-gated Design 1 output.
- Improves send reliability around depleted keypool/change-address errors by
  allowing Nu to refill the keypool and retry the send path when the backend
  reports that a change address cannot be generated.
- Improves shutdown and relaunch behavior by keeping shutdown progress visible
  while backend processes are still exiting.
- Updates peer, seed, traceroute, and diagnostics behavior for the current
  Defcoin network: August 1, 2026 defcoin-only magic enforcement date, dc903
  default-port seed migration, DNS seed source attribution, IPv6 seed display,
  Trippy non-scrolling output mode, Atkinson Hypermobile Mono traceroute font,
  and clearer peer inspection/copy behavior.
- Refreshes branding across Nu and Explore: locked DEFCOIN / CORE NU logo
  ratios, corrected splash/About/navigation lockups, updated Tahoe-style app
  icons, cleaned DMG artwork, and a separate Explore lockup built from the Nu
  family mark.
- Adds Explore Apple Silicon packaging as a separate app/release artifact using
  the shared Nu runtime and the Explore-specific splash/About/navigation
  identity.
- Improves update and packaging behavior across macOS and Windows staging,
  including Velopack-aware update checks, Windows child-process containment,
  clearer fallback installer handling, and release metadata consistency.
- Carries forward Fast Sync and Quick Clone hardening from the 26.6.x line:
  Core validation remains authoritative, UDP is treated as transport, ACK and
  reservation accounting is clearer, and UI metrics distinguish TCP, UDP, and
  fallback paths.

## Packaging

- Visible release label: `26.6.8-alpha`.
- Nu Tahoe build output:
  `source/build/nu-qml-arm64-26.6.8-alpha/DefcoinCoreNu.app`.
- Explore Tahoe build output:
  `source/build/nu-qml-arm64-26.6.8-alpha/DefcoinCoreExplore.app`.
- Staged Nu Apple Silicon artifact:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8-alpha-20260620/apple-silicon/`.
- Staged Explore Apple Silicon artifact:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.8-alpha-20260620/apple-silicon/`.
- Staged Nu Windows 11 x86_64 artifacts:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8-alpha-20260620/windows11-x86_64/Defcoin-Core-Nu-26.6.8-alpha-win64-Setup.exe`
  and
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8-alpha-20260620/windows11-x86_64/Defcoin-Core-Nu-26.6.8-alpha-win64-Portable.zip`.
- Staged Explore Windows 11 x86_64 artifacts:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.8-alpha-20260620/windows11-x86_64/Defcoin-Core-Nu-Explore-26.6.8-alpha-win64-Setup.exe`
  and
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.8-alpha-20260620/windows11-x86_64/Defcoin-Core-Nu-Explore-26.6.8-alpha-win64-Portable.zip`.
- Velopack update-feed files are staged under each Windows artifact folder's
  `velopack/` subdirectory.

## Verification

- Tahoe backend tools report `v26.6.8-alpha`.
- Nu and Explore Apple Silicon app bundles report `CFBundleShortVersionString`
  and `CFBundleVersion` as `26.6.8-alpha`, pass
  `codesign --verify --deep --strict`, and contain arm64 Mach-O binaries.
- Nu and Explore Apple Silicon DMGs pass `hdiutil verify`.
- Windows backend tools and app launchers are PE32+ x86_64 binaries.
- Windows Nu and Explore portable ZIPs contain the expected app executable,
  `Qt6PrintSupport.dll`, `nu/BUILD_INFO.txt`, and `PaperWalletView.qml`, and
  do not contain `.agent.md` companion files or `.DS_Store` metadata.
- Final SHA256 values are generated after packaging and published in the
  release's `SHA256SUMS.txt` asset.

## Remaining Notes

- This is an alpha suffix build. The canonical public patch release remains the
  strict three-number `26.6.8` line if and when the alpha is promoted.
