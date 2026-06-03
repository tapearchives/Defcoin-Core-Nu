# Defcoin Core Nu 26.6.2b Release Notes

Defcoin Core Nu `26.6.2b` is a security hardening update over `26.6.2a`.

## Link Safety

- QML screens now route external link opens through Nu's shared C++ URL
  validation helper.
- The helper allows only valid `http://` and `https://` URLs without embedded
  credentials before opening the operating system browser.

## Clipboard Safety

- Generic copy actions now refuse text that looks like a BIP39 recovery phrase.
- Intentional phrase copying still works from the recovery workflow after the
  user acknowledges the clipboard warning.

## Fast Sync Input Validation

- UDP Fast Sync block requests now reject malformed request IDs that do not
  match Nu's 32-character hexadecimal protocol format.

## Explore

- The Explore app is now named `Defcoin Core Nu Explore` in app metadata,
  installer staging, and distribution paths.
- Explore no longer duplicates the left navigation sections as mid-screen tabs.
- Holder Atlas chart percentages now use indexed supply, Supply Bands and Whale
  Lens use hollow-center pies, and Explorer visualizations include maximized
  pop-out chart windows.
- Movement Map graph nodes can be dragged, and clicking an address node opens
  that address through the selected internal or external Explorer setting.
- Transaction IDs and wallet addresses in shared data tables are Explorer links.
