# Defcoin Core Nu 26.6.4bk

Internal fix build focused on LAN Fast Sync source selection.

## Changes

- Prefer eligible private/local Fast Sync peers when they are available and
  ahead of the local chain.
- Keep public Fast Sync peers as fallback, but do not let public UDP timeout
  behavior dominate a wired-LAN performance test.
- Retains the 26.6.4bj Metrics fixes that separate Core header traffic from
  Core block-body data and report UDP node success/failure counts.

## Notes

- This does not change consensus or block validation. UDP still transports the
  block body selected by Core, and Core still accepts or rejects the result.
- If LAN UDP still measures slow after this change is also ported to Lion, the
  next bottleneck to inspect is Core reservation and validation pacing, not raw
  Ethernet throughput.
