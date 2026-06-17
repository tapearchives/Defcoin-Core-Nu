# NavigationRail.qml Agent Notes

## Purpose

Renders the left navigation rail, route buttons, branding area, and Advanced tools toggle.

## Nu Divergence

- Advanced tools gate Mining, RPC Console, Metrics, and Settings.
- Uses Nu's dark branded rail styling and wallet-first route ordering.
- Centers the official coin + two-line wordmark lockup as one group in the
  left rail. Keep the same visual ratios as `NuBrandLockup.qml` and the splash.

## Do Not Break

- Keep the Advanced tools label readable against the sidebar background.
- Do not expose advanced routes when the toggle is off unless the current route must remain reachable for continuity.
- Keep route names and shortcuts consistent with `Main.qml`.
- Keep the brand lockup centered as a group; do not align the coin independently
  from the wordmark text.

## Verification

- `git diff --check`
- Check navigation contrast and route visibility in a fresh settings state and an existing advanced-enabled state.
