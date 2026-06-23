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
- `26.6.8f-alpha` polishes the Tahoe Mining > Monitor and Benchmark Pools
  surfaces. Miner output keeps its viewing position unless Output focus is
  enabled, line numbers remain monotonic across the rolling 4K-line buffer,
  latest-output-on-top no longer disables focus controls, benchmark tables are
  selectable and sortable, benchmark charts are 1920x1080 bar charts with
  apples-to-apples accepted work/s emphasis, and chart export/copy/open-window
  actions are available. Pool presets now group the Defcoin Host CPU/USB/ASIC
  P2Pool endpoints together with Defcoin.io solo mining, and managed backend
  startup explicitly passes the Defcoin user-agent filter preference so
  Litecoin-family peers cannot pollute the node when filtering is enabled.
- `26.6.8g-alpha` tightens the Tahoe Mining > Benchmark Pools layout and
  comparison output. The table now fits next to the preview chart, omits the
  Status display column, uses accepted work/ms for more readable fair-comparison
  values, pings the bare stratum host without its port, removes the restart-time
  PNG panel, and keeps pool numbers off the chart labels and legend.
- `26.6.8h-alpha` adds a proper Tahoe Mining > Pools preset table with
  separate Pool name, Stratum address, and Pool software fields plus add,
  update, remove, use-selected, and reset-default actions. The Defcoin Host
  CPU/USB/ASIC P2Pool presets now use IP-based stratum endpoints while keeping
  readable host:port names, and Mining Benchmark latency checks use a built-in
  ten-try HTTPing-style Qt TCP probe instead of launching command-line ping.
- `26.6.8i-alpha` polishes Tahoe Mining > Pools and Benchmark Pools. Presets
  can be reordered by dragging the No. column, optional per-pool payout/password
  fields inherit the general mining settings when blank, the benchmark table
  uses readable accepted work/s x1e6 values with units in headers, the restart
  display column is removed, the preview chart is larger, the Monitor launch
  command no longer redacts the Stratum `-p` value, and the latency check no
  longer sends HTTP bytes to Stratum ports.
- `26.6.8j-alpha` restores Mining > Pools to Nu's reusable table component so
  pool presets are selectable, copyable, sortable, and still reorderable from
  the No. column. It tightens table auto-fit sizing, removes the retired
  `cpu.defcoin.host:13370` preset, lowers the benchmark minimum to 10 seconds,
  fixes the estimated runtime math, and redraws the benchmark PNG with a
  full-height accepted work/s panel, one-line legend, sharper text, and per-bar
  plus average value labels.
- `26.6.8k-alpha` corrects the Benchmark Pools countdown labels so idle
  `Time left` mirrors the current per-pool/cycle/pool-count estimate and the
  live backend ETA no longer adds a fixed ten-second-per-pool latency pad. It
  also moves the live cycle/status line into the control row after `Time left`,
  removes the thick progress divider, and keeps the compact controls/actions on
  one row. Benchmark results now include a compact accepted share-difficulty
  `Diff` column, Work/s hover/chart notes explain that the fairer speed score
  sums accepted `Submitted Diff` values per second, uses a conservative
  target-equivalent fallback only when an accepted share lacks a matched
  difficulty row, and chart average labels sit to the right of their averaged
  bar group instead of colliding with candles.
- `26.6.8l-alpha` polishes Mining > Pools and Benchmark Pools again. The
  `.fun` preset/software label is corrected to `UNOMP`, Shift-click cell-range
  selection works immediately across reusable tables, the pool reorder handle
  now shows open/closed hand feedback with a highlighted drop target, and
  benchmark decimal columns use fixed precision for decimal alignment. The
  saved PNG is now branded as `Defcoin Core Nu's Pool Benchmark` with a
  centered title, one-line auto-fitted legend, footer summary, `Conducted on`
  timestamp, clearer fairness wording, restored dashed average overlays, and a
  separate diagnostics sidecar for hashrate/HTTPing when long multi-pass runs
  need the accepted-work chart to use the full width.

## Packaging

- Visible release label for this candidate: `26.6.8l-alpha`.
- Nu Tahoe build output:
  `source/build/nu-qml-arm64-26.6.8l-alpha/DefcoinCoreNu.app`.
- Staged Nu Apple Silicon artifact:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8l-alpha-20260623/apple-silicon/`.
- Staged Nu Windows 11 x86_64 artifacts from the previous cross-platform pass:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8e-alpha-20260622/windows11-x86_64/Defcoin-Core-Nu-v26.6.8e-alpha-Windows-11-x86_64-Setup.exe`
  and
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.8e-alpha-20260622/windows11-x86_64/Defcoin-Core-Nu-v26.6.8e-alpha-Windows-11-x86_64-Portable.zip`.
- Velopack update-feed files are staged under the Windows artifact folder's
  `velopack/` subdirectory.

## Verification

- Tahoe backend tools report `v26.6.8l-alpha`.
- Nu Apple Silicon app bundle reports `CFBundleShortVersionString` and
  `CFBundleVersion` as `26.6.8l-alpha`, passes
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
