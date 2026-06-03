# Defcoin Core Nu 26.6.2h Release Notes

Defcoin Core Nu `26.6.2h` is a Movement Map readability update over
`26.6.2g`.

## Movement Map

- Wallet addresses are now anchored below movement graph circles instead of
  competing with the amount inside the node.
- Node amounts are rounded to whole DFC and shown with the `.-` suffix, such as
  `999.-`.
- Each node calculates a fitted amount font size at draw time so numbers stay
  inside the circle.
- The default node size is larger, and both the main Movement Map and the popout
  now include a node-scale slider.
- Thin blue movement lines are more visible, and movement edges now show
  directional arrowheads.
- Node colors now encode flow role: yellow for net senders, green for net
  receivers, and blue for mixed/relay nodes.
- Hover text now includes plotted flow, inbound and outbound totals, connection
  count, and drag/click guidance.
