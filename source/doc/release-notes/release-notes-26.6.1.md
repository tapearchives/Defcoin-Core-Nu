# Defcoin Core Nu 26.6.1 Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.6.1` is a compatibility and performance release for the
current Nu line. It keeps the inherited Litecoin Core client build identity
unchanged while improving Apple Silicon validation speed, backend cache
selection, and Fast Sync service-bit compatibility.

## Notable Changes

- Added Apple Silicon SHA256 acceleration using Bitcoin Core-derived ARM SHA2
  intrinsics for the SHA256 transform and the two-way SHA256D64 batch path.
- The Apple Silicon backend now logs `arm_shani(1way,2way)` at startup when the
  accelerated path is selected.
- Benchmarked the generic and accelerated SHA256D64 paths on the Mac Mini M4
  Pro using identical generated input over a 1 GiB validation-style workload.
  The output checksum matched exactly:
  `118af3313ef2c383`.
- The benchmark measured `187.53 MiB/s` for the generic path and `1232.94 MiB/s`
  for the ARM SHA2 path, an observed `6.6x` speedup for that double-SHA256 batch
  routine.
- Added an automatic backend `-dbcache` launcher setting for Nu-managed
  backends. If `defcoin.conf` already sets `dbcache`, Nu leaves it alone. If not,
  Nu sizes cache from available RAM while preserving conservative headroom.
- Raised the 64-bit backend `-dbcache` maximum to `32768` MiB so modern machines
  can use more memory during initial block download and validation work.
- Updated the dc903 server build label to `/DefcoinCoreNu:26.6.1/` while keeping
  the existing Defcoin service behavior and Fast Sync service bit.

## Validation And Accuracy Checks

- Built `defcoind` and `defcoin-cli` successfully after adding the ARM SHA2
  crypto object.
- Confirmed configure detects ARM SHA256 intrinsics on Apple Silicon.
- Confirmed `defcoind` startup selects `arm_shani(1way,2way)` and passes the
  backend SHA256 self-test before normal initialization continues.
- Compared generic versus ARM SHA2 SHA256D64 outputs over the same 1 GiB input
  workload before accepting the speedup.
- Confirmed `git diff --check` passes after the source changes.

## Server Compatibility

The dc903 server reports `/DefcoinCoreNu:26.6.1/` and advertises:

- `NETWORK`
- `BLOOM`
- `WITNESS`
- `COMPACT_FILTERS`
- `NETWORK_LIMITED`
- `DEFCOIN_FASTSYNC`

The Fast Sync UDP listener remains active on port `10334`.

## Scope Notes

This is an Apple Silicon-specific SHA256 acceleration for the ARM64 macOS
build. Intel and Windows builds continue to use the existing x86 dispatch paths
where available, including SHA-NI/SSE/AVX paths already present in the
Litecoin-derived backend. Defcoin's proof-of-work remains Scrypt; this change
targets SHA256/SHA256D64 validation and hashing routines used elsewhere in the
Core validation stack.
