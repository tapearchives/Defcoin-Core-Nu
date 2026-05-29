#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <built-app> <destination-platform-dir> <release-version> [dmg-suffix]" >&2
  exit 2
fi

BUILT_APP="$1"
DEST_PLATFORM_DIR="$2"
RELEASE_VERSION="$3"
DMG_SUFFIX="${4:-macOS-AppleSilicon}"
PRODUCT_NAME="Defcoin Core Nu"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_APP="$DEST_PLATFORM_DIR/${PRODUCT_NAME}.app"
DEST_DMG="$DEST_PLATFORM_DIR/Defcoin-Core-Nu-v${RELEASE_VERSION}-${DMG_SUFFIX}.dmg"
DEST_DMG_BACKGROUND="$DEST_PLATFORM_DIR/defcoin-core-nu-dmg-background.png"
RELEASE_DIR="$(dirname "$DEST_PLATFORM_DIR")"

if [ ! -d "$BUILT_APP" ]; then
  echo "built app not found: $BUILT_APP" >&2
  exit 1
fi

mkdir -p "$DEST_PLATFORM_DIR"
rm -rf "$DEST_APP" "$DEST_DMG"

ditto "$BUILT_APP" "$DEST_APP"
chmod -R u+w "$DEST_APP"
rm -f "$DEST_APP/Contents/PlugIns/sqldrivers/libqsqlmimer.dylib"
"$(dirname "$0")/bundle_macos_backend_deps.sh" "$DEST_APP"
install_name_tool -delete_rpath /opt/homebrew/lib "$DEST_APP/Contents/MacOS/DefcoinCoreNu" 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../Frameworks" "$DEST_APP/Contents/MacOS/DefcoinCoreNu" 2>/dev/null || true
xattr -cr "$DEST_APP" || true

codesign --force --deep --sign - "$DEST_APP" >/dev/null
codesign --verify --deep --strict --verbose=4 "$DEST_APP"

DMG_STAGE="$(mktemp -d /tmp/defcoin-nu-dmg-stage.XXXXXX)"
DMG_SETTINGS="$DMG_STAGE/dmgbuild-settings.py"
cleanup() {
  rm -rf "$DMG_STAGE"
}
trap cleanup EXIT

find_python_module() {
  module="$1"
  shift || true
  for candidate in "${DEFCOIN_NU_PACKAGING_PYTHON:-}" /usr/local/bin/python3 /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 /opt/homebrew/bin/python3 /usr/bin/python3 "$(command -v python3 2>/dev/null || true)"; do
    [ -n "$candidate" ] || continue
    [ -x "$candidate" ] || continue
    if "$candidate" -c "import ${module}" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON_PIL="$(find_python_module PIL || true)"
if [ -n "$PYTHON_PIL" ]; then
  "$PYTHON_PIL" - "$DEST_DMG_BACKGROUND" "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" <<'PY'
import os
import sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

out_path, logo_path = sys.argv[1], sys.argv[2]
width, height, scale = 640, 420, 2
rw, rh = width * scale, height * scale
base = Image.new("RGBA", (rw, rh), (8, 14, 22, 255))
draw = ImageDraw.Draw(base, "RGBA")

for y in range(rh):
    t = y / max(rh - 1, 1)
    r = int(10 + 8 * t)
    g = int(18 + 18 * t)
    b = int(30 + 28 * t)
    draw.line([(0, y), (rw, y)], fill=(r, g, b, 255))

draw.rectangle([0, 0, rw, rh], fill=(0, 0, 0, 0))
for x in range(0, rw, 36 * scale):
    draw.line([(x, 0), (x - 190 * scale, rh)], fill=(68, 126, 156, 24), width=1)
for y in range(64 * scale, rh, 62 * scale):
    draw.line([(0, y), (rw, y)], fill=(217, 196, 63, 20), width=1)

if os.path.exists(logo_path):
    logo = Image.open(logo_path).convert("RGBA")
    logo = ImageEnhance.Contrast(logo).enhance(1.05)
    logo.thumbnail((250 * scale, 250 * scale), Image.Resampling.LANCZOS)
    glow = Image.new("RGBA", (logo.width + 80 * scale, logo.height + 80 * scale), (0, 0, 0, 0))
    alpha = logo.getchannel("A")
    glow_alpha = Image.new("L", glow.size, 0)
    glow_alpha.paste(alpha.filter(ImageFilter.GaussianBlur(18 * scale)), (40 * scale, 40 * scale))
    glow_layer = Image.new("RGBA", glow.size, (215, 196, 62, 0))
    glow_layer.putalpha(glow_alpha.point(lambda p: int(p * 0.34)))
    glow.alpha_composite(glow_layer, (40 * scale, 40 * scale))
    glow.alpha_composite(logo, (40 * scale, 40 * scale))
    base.alpha_composite(glow, (34 * scale, 54 * scale))

def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Helvetica.ttf",
    ]
    for path in candidates:
        if path and os.path.exists(path):
            return ImageFont.truetype(path, size * scale)
    return ImageFont.load_default()

title_font = font(34, True)
subtitle_font = font(15, False)
draw.text((266 * scale + 2, 70 * scale + 2), "Defcoin Core Nu", font=title_font, fill=(0, 0, 0, 140))
draw.text((266 * scale, 70 * scale), "Defcoin Core Nu", font=title_font, fill=(226, 212, 83, 255))
draw.text((268 * scale, 112 * scale), "Drag to Applications", font=subtitle_font, fill=(210, 222, 229, 220))

arrow_y = 252 * scale
arrow = [
    (272 * scale, arrow_y - 7 * scale),
    (420 * scale, arrow_y - 7 * scale),
    (420 * scale, arrow_y - 22 * scale),
    (468 * scale, arrow_y),
    (420 * scale, arrow_y + 22 * scale),
    (420 * scale, arrow_y + 7 * scale),
    (272 * scale, arrow_y + 7 * scale),
]
draw.polygon([(x + 3 * scale, y + 3 * scale) for x, y in arrow], fill=(0, 0, 0, 70))
draw.polygon(arrow, fill=(92, 176, 223, 230))

base = base.resize((width, height), Image.Resampling.LANCZOS)
os.makedirs(os.path.dirname(out_path), exist_ok=True)
base.save(out_path)
PY
else
  if command -v magick >/dev/null 2>&1; then
    magick -size 640x420 gradient:'#08121e-#12263a' \
      "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" -resize 250x250 -gravity West -geometry +40+0 -composite \
      -fill '#e2d453' -pointsize 34 -gravity NorthWest -annotate +266+70 'Defcoin Core Nu' \
      -fill '#d2dee5' -pointsize 15 -annotate +268+112 'Drag to Applications' \
      "$DEST_DMG_BACKGROUND"
  else
    cp -p "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" "$DEST_DMG_BACKGROUND"
  fi
fi

ditto "$DEST_APP" "$DMG_STAGE/${PRODUCT_NAME}.app"
ln -s /Applications "$DMG_STAGE/Applications"
cp -p "$DEST_DMG_BACKGROUND" "$DMG_STAGE/background.png"
cat > "$DMG_SETTINGS" <<EOF
format = 'UDZO'
compression_level = 9
filesystem = 'HFS+'
files = [(r'$DMG_STAGE/${PRODUCT_NAME}.app', '${PRODUCT_NAME}.app')]
symlinks = {'Applications': '/Applications'}
background = r'$DMG_STAGE/background.png'
window_rect = ((100, 100), (640, 420))
default_view = 'icon-view'
show_toolbar = False
show_status_bar = False
show_sidebar = False
icon_size = 96
text_size = 13
arrange_by = None
icon_locations = {
    '${PRODUCT_NAME}.app': (210, 250),
    'Applications': (510, 250),
}
EOF

PYTHON_DMGBUILD="$(find_python_module dmgbuild || true)"
if [ -n "$PYTHON_DMGBUILD" ]; then
  "$PYTHON_DMGBUILD" -m dmgbuild -s "$DMG_SETTINGS" "$PRODUCT_NAME" "$DEST_DMG" >/dev/null
else
  mkdir -p "$DMG_STAGE/.background"
  mv "$DMG_STAGE/background.png" "$DMG_STAGE/.background/background.png"
  hdiutil create -volname "$PRODUCT_NAME" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DEST_DMG" >/dev/null
fi
hdiutil verify "$DEST_DMG"

touch -ch "$RELEASE_DIR" "$DEST_PLATFORM_DIR" "$DEST_APP" "$DEST_DMG" "$DEST_DMG_BACKGROUND"

STAMP_FILE="$DEST_PLATFORM_DIR/BUILD_STAGED_AT.txt"
{
  echo "Defcoin Core Nu staged distribution"
  echo "Release: $RELEASE_VERSION"
  echo "Staged at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Built app: $BUILT_APP"
  echo "App: $DEST_APP"
  echo "DMG: $DEST_DMG"
  echo "DMG background: $DEST_DMG_BACKGROUND"
} > "$STAMP_FILE"
touch -ch "$STAMP_FILE"

if command -v SetFile >/dev/null 2>&1; then
  FINDER_DATE="$(date '+%m/%d/%Y %H:%M:%S')"
  for path in "$RELEASE_DIR" "$DEST_PLATFORM_DIR" "$DEST_APP" "$DEST_DMG" "$DEST_DMG_BACKGROUND" "$STAMP_FILE"; do
    SetFile -d "$FINDER_DATE" "$path" >/dev/null 2>&1 || true
    SetFile -m "$FINDER_DATE" "$path" >/dev/null 2>&1 || true
  done
fi

echo "staged app: $DEST_APP"
echo "staged dmg: $DEST_DMG"
echo "dmg background: $DEST_DMG_BACKGROUND"
