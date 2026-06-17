# Defcoin Core Nu UI Tables and Lists

This is part two of the Nu UI design-language notes. It focuses on tables,
lists, transaction histories, peer lists, generated requests, logs, and other
dense data surfaces.

## Current Pattern

- Nu uses white/off-white work surfaces for wallet-facing tables and darker
  technical surfaces for Metrics, console, traceroute, and diagnostics.
- Many lists sit inside panels that also contain controls, explanatory text,
  and status rows.
- Several tables are readable but vertically constrained by page headers,
  summary cards, button rows, or surrounding panels.
- Sorting, hiding, deleting, copying, and filtering behavior is not yet
  consistent across transaction, request, peer, log, wallet-file, and mining
  output surfaces.

## Design Problem

Dense wallet software needs the table to be the primary work surface. When
headers, cards, and explanatory copy consume too much vertical space, the user
gets a dashboard that looks polished but works slowly: fewer rows are visible,
scrolling increases, and patterns become harder to notice.

The highest-value table interactions should be available where the data lives:
sort, filter, copy, inspect, hide/archive, delete where safe, and open details.
Repeated surrounding text should move to hover text, empty-state text, or a
compact help affordance.

## Table Surface Principles

- **Rows first**: table-heavy pages should spend most vertical space on rows.
- **Compact headers**: title and status copy should compress after first-run
  onboarding.
- **Local actions**: row actions should live near the selected row or in a
  stable toolbar that clearly responds to selection.
- **Column agency**: users should be able to sort common columns and hide
  columns that are not useful for their current task.
- **Copy everywhere**: selectable text, error text, addresses, txids, peer
  endpoints, and log lines should have predictable copy support.
- **Safe deletion semantics**: destructive actions must distinguish between
  deleting local UI history, hiding a row, removing an address-book entry, and
  deleting actual wallet data.
- **Persisted preferences**: column widths, Details mode, visible columns, and
  sort order should survive restart when they help repeated use.

## Page Improvement Targets

### Home and Transactions

- Reduce top summary height when the wallet is loaded and healthy.
- Add quick filters: sent, received, mined, pending, watch-only, and date range.
- Add a compact transaction-inspection drawer instead of making every detail
  compete for table height.
- Let users hide low-value historical rows locally without deleting wallet
  records.

### Receive

- Keep the QR/address preview synchronized with selected generated requests.
- Add generated-request sort by date, label, amount, and address.
- Let users archive old requests locally so the active request list stays short.
- Keep the date column visible by default because request age is practical
  wallet information.

### Wallet Files and Tools

- Keep file/tool buttons from crowding the right edge by wrapping action groups
  or moving advanced actions into a local toolbar.
- Distinguish active wallet files, backups, watch-only imports, and paper-wallet
  workflows with compact badges rather than long explanatory blocks.

### Paper Wallet

- Keep the interactive generator scrollable, but avoid brand/logo decoration in
  the GUI. The printout owns the paper-wallet design.
- Put entropy status, Generate, Clear, Preview, and Print into a stable action
  row that never presses against a window corner.
- Treat generated private-key material as a temporary session object: no table,
  no history, no saved list.

### Metrics Status and Traffic

- Default view should answer: Is sync working, which method is active, how fast
  is it moving, and what is failing?
- Details view can expose protocol counters, packet/chunk specifics, and peer
  diagnostics.
- Keep table row height auto-fit, but split long metrics into multiple rows
  instead of creating three-line cells.

### Peers

- Keep the simple peer table fast and compact.
- Move deep per-peer metadata into the Inspect Peer panel.
- Persist useful sorting: LAN/workstation group, services, ping, traffic, and
  last block activity.
- Group same-machine rows by `node_unique_id` visually, but keep Core peer ids
  unchanged for actions.

### RPC Console, Logs, Mining Monitor, and Trippy

- Use terminal-style views only where streaming technical output is the product.
- Keep Follow Tail stable and do not jump back to the top during refresh.
- Add selectable/copyable line output everywhere.
- Cap retained output and throttle UI updates so high-volume miner logs do not
  lock the interface.

## Recommended Shared Controls

- Shared table toolbar: filter box, column chooser, copy selected, inspect
  selected, hide/archive selected, export visible rows.
- Per-table Details toggle: globally linked where it changes diagnostic
  density, local where it changes a specific list.
- Compact empty states: one sentence plus the next action.
- Persistent column model: width, order, visibility, sort column, sort
  direction.
- Action disclosure: destructive or wallet-affecting actions stay explicit;
  harmless local display actions can be quicker.

## Color Guidance

- Use blue for active selection/focus, not for every clickable table cell.
- Use green only for healthy/live/success states.
- Use amber for incomplete, delayed, or caution states.
- Use red only for errors, rejected work, failed validation, or destructive
  actions.
- Avoid decorative color in dense tables; let color mean state or action.

## Next Practical Pass

1. Inventory every table/list surface and record which supports sorting,
   filtering, copying, details, deletion/hiding, and persisted column widths.
2. Create a reusable Nu table toolbar component.
3. Convert one high-value page first, likely Transactions or Peers, then reuse
   the pattern across Receive, Metrics, Wallet Files, and logs.
4. Add a small local display-history model for hide/archive actions that never
   deletes wallet records.
5. Re-test large-wallet behavior with thousands of addresses and long
   transaction histories before copying the pattern widely.
