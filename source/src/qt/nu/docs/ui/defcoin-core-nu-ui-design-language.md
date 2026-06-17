# Defcoin Core Nu UI Design Language

This note describes the current Nu interface language for future UI work. It is an internal design reference, not marketing copy.

## Core Palette

- **Near-black sidebar**: Used for the persistent navigation rail and brand area. It makes the app feel like a serious node tool and gives the v26 coin/wordmark strong contrast.
- **Purple undertone**: Used as a subtle identity color in hover outlines, panel glows, and analytics-oriented surfaces. Purple should communicate advanced tooling, protocol depth, and Defcoin-specific identity. It should stay restrained; it is an accent, not a whole-screen wash.
- **Gold**: Reserved for the Defcoin coin mark, logo emphasis, and rare brand-forward moments. Do not use gold for routine warnings because it competes with the coin.
- **Light blue / sky accent**: Used for keyboard focus, active outlines, selection focus, chart send traffic, and precise interaction affordances. It should mean "this control or datum is active/selected/interactive."
- **Green**: Used for healthy network/wallet state, received traffic, connected peers, accepted work, and successful operations. It should mean "good, live, accepted, available."
- **Red**: Used for destructive actions, errors, failed validation, rejected mining shares, and warnings that can lose funds. It should not be used for decorative contrast.
- **Yellow / amber**: Used for caution and incomplete states, especially private-key handling, slow sync, or "needs attention but not failed."
- **White/off-white content area**: Used for wallet-facing work surfaces where readability matters. Dense data tables and transaction histories should stay high contrast and quiet.
- **Matrix green console style**: Reserved for traceroute/terminal-like diagnostics such as Trippy. It should signal "live technical stream" and should not be used for ordinary wallet text.

## Graph Colors

- **Received traffic** defaults green because incoming blocks, headers, and peer data are "network intake."
- **Sent traffic** defaults blue because outgoing traffic is an active signal from this node.
- **Detailed traffic components** should remain in the same lane as their parent direction: received variants stay green-adjacent, sent variants stay blue-adjacent. Avoid using the same apparent color for unrelated protocols.
- **Fast Sync UDP and Quick Clone UDP** may be split in detailed views, but simple views should keep total RX/TX first so users can understand movement at a glance.

## Interaction Cues

- Navigation buttons use a dark rail background, a white selected state, and a subtle purple hover outline. The hover outline gives tactile feedback without overpowering the selected page.
- Keyboard focus remains blue and should visually outrank hover. A user tabbing through controls needs a clear, predictable focus path.
- Primary action buttons use stronger fill and weight. Secondary buttons should look clickable but quieter.
- Dangerous actions require red styling and explanatory hover text or dialog copy.

## Layout Principles

- Default pages should be scannable first, detailed second.
- Header telemetry should use stable columns and avoid jitter as numbers change.
- Table-heavy pages should use compact headers and spend vertical space on rows.
- Advanced tools should remain behind the Advanced toggle unless they are needed for normal wallet use.
- Sensitive key material must never be displayed in cramped controls. Paper Wallet and recovery workflows should scroll cleanly, use clear warnings, and keep copy/print actions explicit.

## Improvement Opportunities

- Establish named semantic tokens for purple hover, brand gold, caution amber, and terminal green instead of inline colors.
- Audit all charts so their simple and detailed modes use the same color semantics.
- Add a compact "status story" hierarchy: health first, sync method second, failure/success detail third.
- Consider a formal visual state guide for selected, hovered, focused, disabled, destructive, warning, and success controls.
- Replace any remaining one-off dark surfaces with reusable panel variants so hover and focus behavior stays consistent.
