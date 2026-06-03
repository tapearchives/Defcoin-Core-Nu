# Defcoin Core Nu 26.6.3g Release Notes

Defcoin Core Nu `26.6.3g` is a Nu Explore Droid Trails and Relationship Graph
UI update over `26.6.3f`.

## Nu Explore Droid Trails

- Removes the Explorer index status box from Analyze views while keeping it on
  the Index Engines screen.
- Moves the Droid Trails PDF action into the top-right header area and moves the
  Droid Trails, DC25 Payout Hunt, and DC25 Attack Chain tabs under the header
  description.
- Makes the Coindroids story text selectable and copyable, with the general
  Droid Trails intro shown only in the Droid Trails tab.
- Makes the shared Pop out action follow the selected Droid Trails tab.
- Treats Olo as the eighth named DC25 lead and removes tentative-warning
  language from the bundled analysis and UI.

## Relationship Graph

- Adds per-table Chart Relationships actions for Coindroids address tables.
- Allows each table button to replace the active contact set with the addresses
  present in that table before opening the graph.
- Calculates contact current balance, received value, and transaction count
  directly from the local explorer index instead of depending on Top 100 rows.
- Makes the relationship graph draggable, with node size based on balance or
  historical received value and line thickness based on indexed direct flow.
