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

The Explore app variant keeps the same first two lines and adds a third line in
the same type family and weight:

```text
DEFCOIN
CORE NU
EXPLORE
```

The app name is `Defcoin Core Nu Explore`, and the third logo line is set as
`EXPLORE` to match the DEFCOIN / CORE NU lockup.

## Coin Mark

- Use the pure v26 coin mark for logo lockups:
  `src/qt/nu/assets/brand/defcoin-v26-coin.png`.
- Canonical source artwork:
  `/Volumes/TB5_4TB/d/litecoincore/zzz_dev_reference/local-evidence-and-materials/defcoin-core-local-materials/local-only/defcoin_custom_graphics/defcoin2026logo_colorized_sharpv2.png`.
- The canonical source art has a white outside background. Runtime app assets
  must use a transparent-background derivative so the coin can sit cleanly on
  purple, black, white, paper-wallet, and icon surfaces.
- `defcoin-nu-icon-1024.png` and `DefcoinCoreNuNuIcon.icns` should be generated
  from the same v26 coin mark for app-icon contexts. Wordmark lockups should
  still reference `defcoin-v26-coin.png` directly.
- For macOS app icons, use the transparent coin mark directly: no white tile, no
  gray tile, no ring, and no artificial margin. The coin should fill the square
  canvas edge-to-edge at the four cardinal points while preserving the full rim
  and keeping the corner pixels alpha-transparent.
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

The website prototype and reusable QML lockup are the current construction
reference. Expressed as ratios of the wordmark font size:

- Coin size: `1.85em` square.
- Gap between coin and wordmark: `0.46em`, with a practical minimum of the
  local medium spacing token in QML.
- `DEFCOIN` tracking: `0.04em`.
- `CORE` and `NU` tracking: `0.042em`.
- `DEF` to `COIN` join gap: `0.0345em`.
- Inter-line gap between `DEFCOIN` and `CORE NU`: `0.095em`.
- The `CORE NU` line is not a normal text string. Draw `CORE` and `NU` as
  separate runs spread across the exact measured width of the `DEFCOIN` line so
  the left edge of `CORE` aligns with `DEFCOIN` and the right edge of `NU`
  aligns with the `N` in `DEFCOIN`.
- In the Explore variant, the `EXPLORE` line is fit to the first two-line
  lockup width by increasing only positive tracking. Do not use negative
  tracking or horizontal scaling.

Practical PIL reproduction:

1. Draw each character separately using Avenir Next Condensed ExtraBold.
2. Advance by the measured character width plus `0.04em` for `DEFCOIN`.
3. Draw `DEF`, then draw `COIN` at `measure("DEF") + 0.0345em`.
4. Draw `CORE` and `NU` as separate runs at the same x position and at the
   measured right edge of `DEFCOIN`, using `0.042em` tracking.
5. Place the v26 coin mark left of the wordmark at `1.85em` square.

## DMG Layout Notes

- The logo lockup should sit in clean negative space.
- `stage_macos_distribution.sh` must render the third `EXPLORE` line when
  staging `DefcoinCoreExplore.app`; the Nu installer remains the two-line
  DEFCOIN / CORE NU lockup.
- The corner coin stack is decorative and must not crowd the draggable app icon.
- Finder icon labels are dark by default, so dark DMG backgrounds need a quiet
  light label field behind the app and Applications labels.
- Any glow or shine layer must fade to full transparency before it reaches the
  image edge. Hard vertical or horizontal glow edges are a layout defect.
