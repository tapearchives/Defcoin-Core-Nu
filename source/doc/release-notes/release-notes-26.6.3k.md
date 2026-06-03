# Defcoin Core Nu 26.6.3k Release Notes

Defcoin Core Nu `26.6.3k` is a Nu Explore UI polish update over
`26.6.3j`.

## Nu Explore UI Polish

- Moves Droid Trails Refresh, Pop out, and PDF actions into the page header,
  giving the status line and story body more usable width.
- Raises the published Coindroids anchor table above explanatory footnotes so
  the first Droid Trails screen reaches live data sooner.
- Makes the embedded Movement Map easier to read by defaulting to `Top 15`
  plotted movements.
- Uses shorter, edge-clamped Movement Map address labels while preserving full
  address details in hover text and click-through Explorer behavior.
- Lowers the initial Movement Map node scale and uses separate top/bottom graph
  bounds so address labels do not collapse the embedded graph into one lane.
- Quietly stops `NuDataTable` row/cell delegate incubation during component
  teardown, removing noisy shutdown warnings from smoke runs.
