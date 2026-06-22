# Defcoin Core Nu Logo Text

This note defines the app logo lockup used by the navigation rail, splash
screen, DMG artwork, About/help surfaces, and future packaging art. Do not
rebuild the lockup by typing a similar title in a new font; use these
construction rules so spacing stays consistent.

## Text

The Nu wordmark is two lines:

```text
DEFCOIN
CORE NU
```

`DEFCOIN` is one word. There is no normal word space between `DEF` and `COIN`.
The renderer may draw `DEF` and `COIN` as separate runs only to reproduce the
legacy kerning join.

## Coin Mark

- Use the pure v26 coin mark for logo lockups:
  `src/qt/nu/assets/brand/defcoin-v26-coin.png`.
- Canonical source artwork:
  `/Volumes/TB5_4TB/d/litecoincore/zzz_dev_reference/local-evidence-and-materials/defcoin-core-local-materials/local-only/defcoin_custom_graphics/defcoin2026logo_colorized_sharpv2.png`.
- The canonical source art has a white outside background. Runtime app assets
  must use a transparent-background derivative so the coin can sit cleanly on
  purple, black, white, paper-wallet, and icon surfaces.
- `defcoin-nu-icon-1024.png` is the rounded-tile runtime icon used by Qt for
  Dock, Command-Tab, and window icon contexts. It should visually match the
  Finder/AppIcon composition, not the transparent foreground coin alone.
- `DefcoinCoreNuNuIcon.icns` and the Icon Composer foreground should be
  generated from the same v26 coin mark for app-icon contexts. Wordmark lockup
  generation should still start from `defcoin-v26-coin.png`.
- For macOS app icons, use the transparent coin mark as the Icon Composer
  foreground over the system rounded white tile. Crop the source coin by its
  alpha bounds before scaling. The foreground coin alpha-edge diameter should
  be `0.8125` of the Finder white tile diameter, matching the measured Chrome
  circle-to-tile ratio from Finder screenshots. Do not measure the whole square
  PNG canvas as the coin diameter. Do not add haze, glow, or shadow at the
  bottom of the coin foreground.
- The old `defcoin-nu-coin-stack-hires.png` artwork is legacy decorative art and
  is not part of the current product logo lockup.
- The coin always appears to the left of the wordmark when the wordmark is
  present.

## Typeface

- Preferred family: `Avenir Next Condensed`.
- Weight: `ExtraBold`.
- Fallbacks: `Arial Bold`, then `Helvetica Bold`.
- Color on dark surfaces: `#f6f6f2`.
- Shadow: low-alpha black, offset by roughly 3 px at 2x render scale.

## Spacing and Ratios

This section is the source of truth for the coin + wordmark lockup. Express
runtime values as ratios of the wordmark font size, where `1em` equals the
rendered wordmark pixel size.

- Coin size: derive the square coin box from the visible wordmark, not from a
  fixed em multiplier. First compute the old locked size as `(DEFCOIN visible
  height + CORE NU visible height + 2 * visible inter-line gap) * 1.045`. Then
  compute the inner-circle-match size as `visible two-line wordmark height /
  0.7039`, where `0.7039` is the measured diameter ratio of the coin's inner
  circle to the full visible coin. The final coin size is halfway between
  those two sizes. This keeps the coin more substantial than the earlier
  lockup without letting it dominate the wordmark.
- Coin alignment: vertically center the coin against the full wordmark block.
  The coin should extend just beyond the top and bottom of the combined text,
  not sit as a small badge next to oversized words.
- Gap between the visible right edge of the coin and the left edge of the
  wordmark: use five-sixths of the measured horizontal gap that separates
  `CORE` and `NU` after the second line is fitted to the `DEFCOIN` width. In
  QML/C++ approximations this is `0.25em` before minimum sizing. Keep `CORE`
  and `NU` distinct words at small sizes.
- `DEFCOIN` tracking: `0.04em`.
- `CORE` and `NU` tracking: `0.038em`.
- `DEF` to `COIN` join gap: `0.0345em`.
- Visual inter-line gap between `DEFCOIN` and `CORE NU`: `0.213em`, measured
  between the visible bottom edge of the first-line glyphs and the visible top
  edge of the second-line glyphs. Runtime layout values may be negative because
  Qt/font line boxes include extra ascender/descender space; tune them until
  this visible glyph gap is reached.
- The letters must never touch or look stacked into one shape. The visible row
  gap should be tighter than the horizontal `CORE`/`NU` word gap.
- The `CORE NU` line is not a normal text string. Draw `CORE` and `NU` as
  separate runs spread across the exact measured width of the `DEFCOIN` line:
  the left edge of `CORE` aligns with the left edge of `DEFCOIN`, and the
  right edge of `NU` aligns with the right edge of `DEFCOIN`.
## Runtime Implementations

- `src/qt/nu/assets/brand/defcoin-core-nu-lockup.png` is the generated
  transparent lockup asset from the construction rules above. QML, splash,
  About, navigation, and DMG art should reuse this asset instead of
  reconstructing the wordmark independently.
- `src/qt/nu/qml/Components/NuBrandLockup.qml` is the canonical QML wrapper for
  the navigation rail, Home, About, and other in-app QML surfaces. It scales
  the generated lockup assets from a base `256px` wordmark size.
- `src/qt/nu/app/main.cpp` renders the startup splash by drawing the same
  generated lockup asset at the splash wordmark size.
- `stage_macos_distribution.sh` owns DMG background art. If it renders the
  product wordmark, use the same generated lockup asset instead of typing a
  separate approximation.
- When the ratios change, update this file, `NuBrandLockup.qml`, the splash
  renderer, the generated lockup PNGs, and any packaging renderer in the same
  build.

Practical PIL reproduction:

1. Draw each character separately using Avenir Next Condensed ExtraBold.
2. Advance by the measured character width plus `0.04em` for `DEFCOIN`.
3. Draw `DEF`, then draw `COIN` at `measure("DEF") + 0.0345em`.
4. Draw the second row so the visible glyph gap between rows is `0.213em`.
5. Draw `CORE` and `NU` as separate runs using `0.038em` tracking; place
   `CORE` at the same x position as `DEFCOIN`, and place `NU` so its measured
   right edge aligns with the measured right edge of `DEFCOIN`. The gap
   between `CORE` and `NU` is therefore whatever remains after that alignment,
   with a `0.30em` minimum.
6. Place the v26 coin mark left of the wordmark and center it against the
   combined two-line wordmark block. Set its square size halfway between the
   old locked size and the inner-circle-match size described above.
7. Set the visible gap between the coin's right edge and the wordmark's left
   edge to five-sixths of the measured `CORE`/`NU` word gap.
## DMG Layout Notes

- The logo lockup should sit in clean negative space and be centered left to
  right in the DMG window.
- `stage_macos_distribution.sh` must use the two-line DEFCOIN / CORE NU
  lockup for the Nu installer.
- Do not place decorative coin stacks in the top-left corner of the DMG
  background; they compete with the centered product logo.
- Finder icon labels are dark by default, so dark DMG backgrounds need a quiet
  light label field behind the app and Applications labels.
- Any glow or shine layer must fade to full transparency before it reaches the
  image edge. Hard vertical or horizontal glow edges are a layout defect.
