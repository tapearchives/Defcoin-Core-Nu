# Defcoin Core Nu 26.6.3f Release Notes

Defcoin Core Nu `26.6.3f` is a Nu Explore Coindroids DC25 forensics update over
`26.6.3b`.

## Nu Explore Coindroids

- Adds bundled DC25 attack-address chain-forensics data generated from the
  2026-06-03 Coindroids CSV reports.
- Adds a DC25 Attack Chain story tab with live metrics, an interactive
  attack-address cohort chart, hover details, click-through explorer lookups,
  and drill-down tables for QR seeds, attack candidates, source/ammo clips, and
  the tentative Olo candidate.
- Adds a dedicated DC25 attack-chain pop-out chart with relationship-set
  shortcuts.
- Separates legacy `3...` QR P2SH strings from the indexed `M...` P2SH
  addresses used by Nu Explore.
- Bumps the Droid Trails cache schema to force one rebuild of the richer
  Coindroids analysis cache.

## Contact Sets

- Creates prebuilt Coindroids contact sets for DC25 QR Seeds, Attack Cohort,
  Source Ammo, Olo Tentative, and the combined DC25 Investigation set.
- Adds Coindroids story buttons that load those saved Contact Sets and open the
  Relationship chart for immediate visual review.

## Story Report

- Bundles the placeholder `coindroids_defcoin_forensics_story_report_v6.pdf`
  and adds a PDF launch action that opens it with the macOS default PDF app.
