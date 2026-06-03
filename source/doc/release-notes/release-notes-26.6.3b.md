# Defcoin Core Nu 26.6.3b Release Notes

Defcoin Core Nu `26.6.3b` is a Nu Explore contact-set update over `26.6.3a`.

## Nu Explore Contacts

- Adds named Contact Sets for the Nu Explore relationship graph.
- Allows loading, saving, creating empty sets, renaming, and deleting saved
  sets from the Contacts view.
- Migrates the prior single Explore contacts list into a saved `Default` set.
- Keeps the legacy single-contact settings snapshot synchronized for local
  compatibility while using the named set database as the primary source.
- Routes manual contact edits and Coindroids game-address imports into the
  active Contact Set, so Relationship graphing follows the selected address
  cluster set.
