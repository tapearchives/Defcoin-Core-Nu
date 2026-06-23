# NuDataTable.qml Agent Notes

## Purpose

Reusable Nu table component with selectable rows, sortable columns, copy behavior, saved column widths, auto-fit/reset support, row wrapping, and hover text.

## Nu Divergence

- Supports many Nu-specific tables: peers, status rows, transactions, wallets, receive requests, logs, banned peers, and explorer-derived tables.
- Column width logic is sensitive because users repeatedly requested dense tables that still avoid clipping.
- Callers may opt into centered header text with `centerHeaderText` for dense
  diagnostic tables whose numeric/body cells still need their normal alignment.
- Callers may opt into `shrinkToContent` when the table frame should hug
  measured columns instead of filling the whole available viewport. Use this
  for compact side-by-side layouts where trailing blank table space would steal
  room from charts or detail panes.
- Callers may opt into `rowReorderEnabled` with a `rowReorderColumn`; the
  component must still preserve ordinary cell/range selection, copying, and
  sortable columns. A plain cell click should establish the cell selection
  anchor, and a later Shift-click should select that rectangular range before
  row-range selection is considered.

## Do Not Break

- Column metadata arrays passed by callers must stay aligned; fail gracefully when rows are shorter than headers.
- Preserve selectable/copyable text behavior for diagnostic/status/error rows.
- Keep sort callbacks stable so view switches can preserve sort order.
- Keep drag-to-reorder scoped to its configured column. Do not make every cell
  in a selectable table act as a drag handle. The reorder column should provide
  open-hand hover feedback, closed-hand pressed feedback, and a visible target
  row while dragging.
- Avoid row heights that double for single-line content without reason.
- LAN workstation/source cells reserve extra width for the inline LAN glyph;
  keep the C++ suggested widths and QML delegate margins in sync.

## Verification

- `git diff --check`
- Smoke-test at least one narrow table, one wide table, sorting, row selection, copy, and reset widths.
