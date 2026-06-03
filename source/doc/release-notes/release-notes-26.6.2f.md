# Defcoin Core Nu 26.6.2f Release Notes

Defcoin Core Nu `26.6.2f` is an Explore distribution and Droid Trails clarity
update over `26.6.2e`.

## Explore Distribution

- The Apple Silicon staging script no longer creates `BUILD_STAGED_AT.txt`.
- Defcoin Core Nu Explore distribution folders are flattened to one top-level
  build-folder layer, with platform folders such as `apple-silicon` beneath each
  build.
- Historical build folder names are normalized to
  `Defcoin-Core-Nu-Explore-v26.n.n[a]-YYYYMMDD`.

## Mast Status

- The mast status lights now use stable visible labels such as `Explorer index`,
  `Droid Trails`, and `Network`; fast-changing details remain in hover/help text
  and nearby metrics.

## Droid Trails

- The section now leads with the most interesting Coindroids figures: candidate
  DFC sent, strongest DEF CON window, published largest payout, launch-swarm
  winner, and swarm totals.
- Published recap winners and local-chain launch-swarm recipients are now
  described as separate measurements.
- Published Coindroids anchors and launch-swarm recipient rows are shown before
  lower-level detector tables.

## Build Tooling

- Apple Silicon packages are rebuilt against Qt `6.11.1`.
- The local build machine now has `vulkan-headers` installed, which resolves
  Qt's `WrapVulkanHeaders` CMake discovery warning during Nu configuration.
