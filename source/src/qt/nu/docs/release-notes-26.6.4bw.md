# Defcoin Core Nu 26.6.4bw

Internal Fast Sync benchmark build for Tahoe and Lion.

- Keeps Tahoe on the current UDP Fast Sync scheduler.
- Updates the Lion Fast Sync scheduler to reserve explicit LAN block heights during LAN-only or Core-TCP-disabled benchmark runs, matching Tahoe behavior.
- Preserves public Fast Sync behavior through Core's normal `reserve-next` path.
- Keeps sync benchmark logging through `NU_SYNC_BENCHMARK_START` and `NU_SYNC_BENCHMARK_COMPLETE`.
