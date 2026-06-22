# NuDataTable.qml Agent Notes

## Purpose

Reusable Nu table component with selectable rows, sortable columns, copy behavior, saved column widths, auto-fit/reset support, row wrapping, and hover text.

## Nu Divergence

- Supports many Nu-specific tables: peers, status rows, transactions, wallets, receive requests, logs, banned peers, and explorer-derived tables.
- Column width logic is sensitive because users repeatedly requested dense tables that still avoid clipping.

## Do Not Break

- Column metadata arrays passed by callers must stay aligned; fail gracefully when rows are shorter than headers.
- Preserve selectable/copyable text behavior for diagnostic/status/error rows.
- Keep sort callbacks stable so view switches can preserve sort order.
- Avoid row heights that double for single-line content without reason.
- LAN workstation/source cells reserve extra width for the inline LAN glyph;
  keep the C++ suggested widths and QML delegate margins in sync.

## Verification

- `git diff --check`
- Smoke-test at least one narrow table, one wide table, sorting, row selection, copy, and reset widths.
