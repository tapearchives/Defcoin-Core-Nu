# Defcoin Core Nu 26.3.1 Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.3.1` is a cleanup release for the current Nu desktop
wallet line. It keeps the `26.3.0` network, wallet, peer-magic, and
User-Agent filtering behavior while reducing packaged Nu assets to the files
the Qt Quick shell actually uses.

Notable release changes:

- Runtime asset staging now copies an explicit allowlist of Nu icons and brand
  assets instead of the whole asset directory.
- Unused Nu image drafts, duplicate icon outputs, and Finder metadata were
  removed from source and packages.
- Build notes and release-facing documentation were tightened to describe the
  current release only.
- The optional mainnet bootstrap pack was withdrawn after later witness-data
  repair work showed that this snapshot may have been built from a
  pre-repair, stripped-witness chain state.

## Optional Bootstrap Pack

The previous `Defcoin-bootstrap-mainnet-2332283.zip` asset should not be used.
It has been withdrawn while a fresh bootstrap is rebuilt from a
witness-complete chain snapshot. Use normal network sync until a replacement
bootstrap pack is published.

Technical details are maintained in
`doc/defcoin-core-nu-technical-guide.md`.
