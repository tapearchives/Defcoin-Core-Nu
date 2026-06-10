# Defcoin Core Nu 26.6.4cf Release Notes

Date: 2026-06-10

## Metrics Traffic Graph

- Corrected Metrics > Traffic so Quick Clone is not shown as a separate transport family.
- The graph now shows three traffic groups only:
  - Total received/sent: solid green/blue
  - TCP received/sent: dashed teal/blue
  - UDP received/sent: dotted lime/purple
- UDP totals include both Fast Sync UDP and Quick Clone UDP traffic.
- The footer grid now shows TCP, UDP, and Total traffic for `Total rec'd:` and `Total sent:`.
- Quick Clone copy rate remains visible on Metrics > Status, where it belongs operationally.

## Startup Guard

- Improved duplicate-instance handling.
- If another Nu window is using the same data directory, pressing OK now checks again instead of exiting immediately.
- Added a `Close Other Instance` action for users who want Nu to request the existing GUI process to close.

## Porting Notes

- Lion, Catalina, and Windows builds should port the same Traffic graph/footer model.
- Keep Quick Clone UDP bytes in the normal UDP counters. Do not add them to totals separately.
- Keep Quick Clone subset counters for Status text and debugging only.
