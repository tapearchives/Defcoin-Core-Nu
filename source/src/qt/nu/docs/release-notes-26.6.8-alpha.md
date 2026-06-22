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
- Corrects new SQLite descriptor wallet contents so active receive/change
  managers are created for Defcoin's current spendable address types, with
  inactive reserved MWEB descriptors stored for future activation without
  populating those future-only keypools now.
- Improves shutdown and relaunch behavior by keeping shutdown progress visible
  while backend processes are still exiting.
- Updates peer, seed, traceroute, and diagnostics behavior for the current
  Defcoin network: August 1, 2026 defcoin-only magic enforcement date, dc903
  default-port seed migration, DNS seed source attribution, IPv6 seed display,
  Trippy non-scrolling output mode, Atkinson Hypermobile Mono traceroute font,
  and clearer peer inspection/copy behavior.
- Refreshes Nu branding: locked DEFCOIN / CORE NU logo ratios, corrected
  splash/About/navigation lockups, updated Tahoe-style app icons, and cleaned
  DMG artwork.
- Improves update and packaging behavior across macOS and Windows staging,
  including Velopack-aware update checks, Windows child-process containment,
  clearer fallback installer handling, and release metadata consistency.
- Carries forward Fast Sync and Quick Clone hardening from the 26.6.x line:
  Core validation remains authoritative, UDP is treated as transport, ACK and
  reservation accounting is clearer, Sync Method stats describe accepted blocks
  as one UDP/Core-TCP split, tied or empty accepted-block samples no longer
  claim one transport is faster, and UI metrics distinguish TCP, UDP, and
  fallback paths.
- `26.6.8c-alpha` adds a peer-table polish pass: the Node column stays a raw
  Core peer id, same-node LAN rows show `G1: Name` in the workstation/source
  column, LAN glyph sizing is included in auto-fit widths, Quick Clone wait
  strings identify the receiver-local backend gate, scoped IPv6 link-local LAN
  discovery is preserved for Nu UDP while Core addnode skips those scoped
  endpoints, and Debug/Mining logs gain consistent follow-tail, recent-first,
  filter, remove, find, copy, and visible-scrollbar behavior.
- `26.6.8d-alpha` adds a Tahoe Mining > Benchmark Pools tab. The benchmark
  reuses saved miner settings, cycles through preset pools plus a distinct
  custom pool, runs a ten-ping check before each pool, records hashrate,
  accepted shares, accepted share-difficulty work/s, ping, and restart timing,
  and autosaves latest plus timestamped JSON/PNG chart artifacts for later
  loading/export. Raw accepted share count remains visible, but pool comparison
  uses accepted work/s so pools that assign different share difficulty can be
  compared more fairly. The live benchmark line shows current pool elapsed time
  and time left, while the summary uses `Time left` instead of ETA wording.
- `26.6.8e-alpha` carries the active Tahoe alpha forward as a Nu-only release
  boundary build and rebuilds the matching Windows 11 x86_64 package. The Nu
  repo, docs, changelog, source tree, and staged packages exclude sibling
  product targets, screenshots, data files, QML, and release notes.

## Packaging

- Visible release label for this candidate: `26.6.8e-alpha`.
- Nu Tahoe build output:
  `source/build/nu-qml-arm64-26.6.8e-alpha/DefcoinCoreNu.app`.
- Staged Nu Apple Silicon artifact:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8e-alpha-20260622/apple-silicon/`.
- Staged Nu Windows 11 x86_64 artifacts:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8e-alpha-20260622/windows11-x86_64/Defcoin-Core-Nu-v26.6.8e-alpha-Windows-11-x86_64-Setup.exe`
  and
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8e-alpha-20260622/windows11-x86_64/Defcoin-Core-Nu-v26.6.8e-alpha-Windows-11-x86_64-Portable.zip`.
- Velopack update-feed files are staged under the Windows artifact folder's
  `velopack/` subdirectory.

## Verification

- Tahoe backend tools report `v26.6.8e-alpha`.
- Nu Apple Silicon app bundle reports `CFBundleShortVersionString` and
  `CFBundleVersion` as `26.6.8e-alpha`, passes
  `codesign --verify --deep --strict`, and contains arm64 Mach-O binaries.
- Nu Apple Silicon DMG passes `hdiutil verify`.
- Windows backend tools and app launcher are PE32+ x86_64 binaries.
- Windows Nu portable ZIP contains the expected app executable,
  `Qt6PrintSupport.dll`, `nu/BUILD_INFO.txt`, and `PaperWalletView.qml`, and
  does not contain `.agent.md` companion files or `.DS_Store` metadata.
- Focused Nu `--ui-self-test --allow-multiple` screenshot capture passes for
  Mining > Benchmark Pools with backend autostart disabled.
- Final SHA256 values are generated after packaging and published in the
  release's `SHA256SUMS.txt` asset.

## Remaining Notes

- This is an alpha suffix build. The canonical public patch release remains the
  strict three-number `26.6.8` line if and when the alpha is promoted.
