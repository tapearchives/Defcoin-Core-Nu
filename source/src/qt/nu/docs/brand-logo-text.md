# Defcoin Core Nu Logo Text

This note defines the app wordmark used by the splash screen, DMG artwork, and
future packaging art. Do not rebuild the wordmark by typing a similar title in a
new font; use these construction rules so spacing stays consistent.

## Text

The Nu wordmark is two lines:

```text
DEFCOIN
CORE NU
```

`DEFCOIN` is one word. There is no normal word space between `DEF` and `COIN`.
The renderer may draw `DEF` and `COIN` as separate runs only to reproduce the
legacy kerning join.

## Typeface

- Preferred family: `Avenir Next Condensed`.
- Weight: `ExtraBold`.
- Fallbacks: `Arial Bold`, then `Helvetica Bold`.
- Color on dark surfaces: `#f6f6f2`.
- Shadow: low-alpha black, offset by roughly 3 px at 2x render scale.

## Spacing

The source splash renderer in `source/src/qt/nu/app/main.cpp` is canonical:

- Pixel size: `58`.
- Letter spacing: absolute `1.15 px`.
- `DEF` and `COIN` are drawn as separate runs.
- Legacy `DEF` to `COIN` join gap: `2 px` after the measured `DEF` run.
- Second line offset: `50 px` below the first line baseline region.
- The `N` in `COIN` and the `U` in `NU` should optically right-align when the
  wordmark is set in the two-line lockup.

Practical PIL reproduction:

1. Draw each character separately using Avenir Next Condensed ExtraBold.
2. Advance by the measured character width plus `1.15 px`.
3. Draw `DEF`, then draw `COIN` at `measure("DEF") + 2 px`.
4. Draw `CORE NU` at the same x position, `50 px` lower.

## DMG Layout Notes

- The wordmark should sit in clean negative space, not on top of the coin stack.
- The corner coin stack is decorative and must not crowd the draggable app icon.
- Finder icon labels are dark by default, so dark DMG backgrounds need a quiet
  light label field behind the app and Applications labels.
- Any glow or shine layer must fade to full transparency before it reaches the
  image edge. Hard vertical or horizontal glow edges are a layout defect.
