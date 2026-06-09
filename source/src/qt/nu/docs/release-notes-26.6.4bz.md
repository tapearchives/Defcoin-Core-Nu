# Defcoin Core Nu 26.6.4bz

Internal Fast Sync recovery build for Tahoe and Lion.

## Changes
- Added active recovery for UDP Fast Sync block requests that time out after a
  sender served data but the receiver never stages or accepts the block.
- Timed-out UDP requests now clear stale peer verification, release the Core
  block reservation, log `NU_UDP_FASTSYNC_TIMEOUT`, and immediately reschedule
  Fast Sync so the block can be requested again.
- Added diagnostics for ignored UDP chunks with unknown request ids.
- Documented the future IPv4+IPv6 logical peer cleanup: keep both transport
  lanes, but eventually aggregate one physical LAN workstation in the UI and
  source accounting.
- Added the `nu_lion_remote_health_gate.sh` test helper so Lion crash dialogs
  and process state are checked and logged before interpreting sync tests.

## Verification Notes
- The live stall that triggered this build showed Lion accepting UDP through
  block 458, Tahoe serving 459-461, and Lion failing to stage/accept those
  blocks afterward.
- Tahoe source-node testing must launch without the LAN-only/TCP-off benchmark
  flags when Tahoe itself needs to catch up to the public chain tip.
- In the later clean gated run, physical Lion had no current crash reporter,
  Tahoe's Local Network Allow gate was clear, and Lion accepted UDP Fast Sync
  blocks from Tahoe. That proves UDP transport and Core acceptance are working
  in isolation; throughput is still not representative while Lion is rebuilding
  headers and saturating CPU.
