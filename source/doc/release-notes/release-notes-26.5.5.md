# Defcoin Core Nu 26.5.5 Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.5.5` adds the first blockchain forensics surface to the
desktop wallet while keeping the chain, wallet, recovery, mining, and explorer
behavior from the current `26.5` line.

## Notable Changes

- Added a new `Forensics` section to the desktop UI.
- Added the first Forensics view, `Irregular Messages`, for unusual text
  payloads embedded permanently in OP_RETURN outputs.
- Added a clean table showing `Block Height`, `Transaction ID`, `Burned Defcoin
  Amount`, `Decoded Text Message`, and a short irregularity label.
- Added a bounded native backend scan using accepted block data rather than
  slow UI-side block parsing.
- Flagged OP_RETURN cases include:
  - nonzero DFC burned into an unspendable output,
  - scripts above the standard 83-byte OP_RETURN relay size,
  - active execution opcodes after OP_RETURN,
  - multiple OP_RETURN outputs in one transaction.

## Technical Notes

The new `scanirregularmessages` RPC scans the active chain in chunks and returns
only flagged rows. It uses `CBlock` transaction data, checks unspendable
OP_RETURN outputs, decodes pushed payload bytes as printable text where
possible, and leaves consensus state unchanged.

Technical details are maintained in
`doc/defcoin-core-nu-technical-guide.md`.
