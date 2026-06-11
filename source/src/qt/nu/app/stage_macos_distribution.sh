#!/usr/bin/env bash
export LC_ALL=C
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <built-app> <destination-platform-dir> <release-version> [dmg-suffix]" >&2
  exit 2
fi

BUILT_APP="$1"
DEST_PLATFORM_DIR="$2"
RELEASE_VERSION="$3"
DMG_SUFFIX="${4:-macOS-AppleSilicon}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILT_APP_BASENAME="$(basename "$BUILT_APP")"
if [[ "$BUILT_APP_BASENAME" == *Explore* || "$BUILT_APP" == *DefcoinCoreExplore* ]]; then
  PRODUCT_NAME="Defcoin Core Nu Explore"
  PRODUCT_SLUG="Defcoin-Core-Nu-Explore"
  APP_EXECUTABLE_NAME="DefcoinCoreExplore"
  DEST_DMG_BACKGROUND_BASENAME="defcoin-core-nu-explore-dmg-background.png"
  DMG_STAGE_TEMPLATE="/tmp/defcoin-explore-dmg-stage.XXXXXX"
  WORDMARK_THIRD_LINE="EXPLORE"
else
  PRODUCT_NAME="Defcoin Core Nu"
  PRODUCT_SLUG="Defcoin-Core-Nu"
  APP_EXECUTABLE_NAME="DefcoinCoreNu"
  DEST_DMG_BACKGROUND_BASENAME="defcoin-core-nu-dmg-background.png"
  DMG_STAGE_TEMPLATE="/tmp/defcoin-nu-dmg-stage.XXXXXX"
  WORDMARK_THIRD_LINE=""
fi
DEST_APP="$DEST_PLATFORM_DIR/${PRODUCT_NAME}.app"
DEST_DMG="$DEST_PLATFORM_DIR/${PRODUCT_SLUG}-v${RELEASE_VERSION}-${DMG_SUFFIX}.dmg"
LEGACY_DMG_BACKGROUND="$DEST_PLATFORM_DIR/${DEST_DMG_BACKGROUND_BASENAME}"
RELEASE_DIR="$(dirname "$DEST_PLATFORM_DIR")"

if [ ! -d "$BUILT_APP" ]; then
  echo "built app not found: $BUILT_APP" >&2
  exit 1
fi

mkdir -p "$DEST_PLATFORM_DIR"
rm -rf "$DEST_APP" "$DEST_DMG" "$LEGACY_DMG_BACKGROUND"

ditto "$BUILT_APP" "$DEST_APP"
chmod -R u+w "$DEST_APP"
NU_RESOURCE_DIR="$DEST_APP/Contents/Resources/nu"
mkdir -p "$NU_RESOURCE_DIR"
rm -rf "$NU_RESOURCE_DIR/qml" "$NU_RESOURCE_DIR/assets"
ditto "$SCRIPT_DIR/../qml" "$NU_RESOURCE_DIR/qml"
ditto "$SCRIPT_DIR/../assets" "$NU_RESOURCE_DIR/assets"
APP_PLIST="$DEST_APP/Contents/Info.plist"
if [ -f "$APP_PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleName $PRODUCT_NAME" "$APP_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleName string $PRODUCT_NAME" "$APP_PLIST"
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $PRODUCT_NAME" "$APP_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $PRODUCT_NAME" "$APP_PLIST"
fi
rm -f "$DEST_APP/Contents/PlugIns/sqldrivers/libqsqlmimer.dylib"
find "$DEST_APP/Contents/Frameworks" -type f \( -name '*.a' -o -name '*.la' \) -delete 2>/dev/null || true
"$(dirname "$0")/bundle_macos_backend_deps.sh" "$DEST_APP"
PYTHON_FOR_QT_REPAIR="${DEFCOIN_NU_PACKAGING_PYTHON:-$(command -v python3)}"

find_existing_dir() {
  for candidate in "$@"; do
    [ -n "$candidate" ] || continue
    if [ -d "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

if [ -z "${DEFCOIN_NU_QT_ROOT:-}" ] \
  && [ -d "$DEST_APP/Contents/Frameworks/QtCore.framework" ] \
  && [ -f "$DEST_APP/Contents/PlugIns/platforms/libqcocoa.dylib" ]; then
  echo "Using Qt runtime already bundled in $DEST_APP"
else
  QT_ROOT="${DEFCOIN_NU_QT_ROOT:-/opt/homebrew}"
  QT_PLUGIN_ROOT="$(find_existing_dir \
    "$QT_ROOT/plugins" \
    "$QT_ROOT/share/qt/plugins" \
    "$QT_ROOT/opt/qt/plugins" \
    "$QT_ROOT/opt/qt/share/qt/plugins" \
    "$QT_ROOT/opt/qtbase/share/qt/plugins" \
    "/opt/homebrew/share/qt/plugins" \
    "/opt/homebrew/opt/qtbase/share/qt/plugins" \
    "/opt/homebrew/opt/qt/share/qt/plugins" \
    "/usr/local/share/qt/plugins")"
  QT_QML_ROOT="$(find_existing_dir \
    "$QT_ROOT/qml" \
    "$QT_ROOT/share/qt/qml" \
    "$QT_ROOT/opt/qt/qml" \
    "$QT_ROOT/opt/qt/share/qt/qml" \
    "$QT_ROOT/opt/qtdeclarative/share/qt/qml" \
    "/opt/homebrew/share/qt/qml" \
    "/opt/homebrew/opt/qtdeclarative/share/qt/qml" \
    "/opt/homebrew/opt/qt/share/qt/qml" \
    "/usr/local/share/qt/qml")"
  "/bin/sh" "$(dirname "$0")/deploy_macos_qt_runtime.sh" "$QT_ROOT" "$QT_PLUGIN_ROOT" "$QT_QML_ROOT" "$DEST_APP"
  "$PYTHON_FOR_QT_REPAIR" "$(dirname "$0")/repair_macos_qt_bundle.py" "$QT_ROOT" "$DEST_APP"
fi
find "$DEST_APP/Contents/Frameworks" -type f \( -name '*.a' -o -name '*.la' \) -delete 2>/dev/null || true

APP_EXE="$DEST_APP/Contents/MacOS/$APP_EXECUTABLE_NAME"
while IFS= read -r rpath; do
  case "$rpath" in
    /opt/homebrew/lib|*"/toolchains/qt/"*|*"/Qt/"*"/macos/lib")
      install_name_tool -delete_rpath "$rpath" "$APP_EXE" 2>/dev/null || true
      ;;
  esac
done < <(otool -l "$APP_EXE" | awk '
  /LC_RPATH/ {
    getline
    getline
    sub(/^ *path /, "")
    sub(/ \(offset.*$/, "")
    print
  }
')
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_EXE" 2>/dev/null || true
xattr -cr "$DEST_APP" || true

sign_macho_tree() {
  local root="$1"
  local exclude_dir="${2:-}"
  while IFS= read -r -d '' candidate; do
    chmod u+w "$candidate" 2>/dev/null || true
    codesign --force --sign - --timestamp=none "$candidate" >/dev/null
  done < <("$PYTHON_FOR_QT_REPAIR" - "$root" "$exclude_dir" <<'PY'
import os
import sys

root = sys.argv[1]
exclude_dir = sys.argv[2]
magics = {
    b"\xfe\xed\xfa\xce",
    b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xcf",
    b"\xcf\xfa\xed\xfe",
    b"\xca\xfe\xba\xbe",
    b"\xbe\xba\xfe\xca",
    b"\xca\xfe\xba\xbf",
    b"\xbf\xba\xfe\xca",
}
paths = []
for base, dirs, files in os.walk(root, followlinks=False):
    for name in files:
        path = os.path.join(base, name)
        if exclude_dir and os.path.commonpath([path, exclude_dir]) == exclude_dir:
            continue
        try:
            with open(path, "rb") as handle:
                head = handle.read(4)
        except OSError:
            continue
        if head in magics:
            paths.append(path)
for path in sorted(paths):
    sys.stdout.buffer.write(path.encode() + b"\0")
PY
)
}

sign_macho_tree "$DEST_APP/Contents" "$DEST_APP/Contents/MacOS"
if [ -x "$APP_EXE" ]; then
  chmod u+w "$APP_EXE" 2>/dev/null || true
  codesign --force --sign - --timestamp=none "$APP_EXE" >/dev/null
fi
codesign --force --sign - --timestamp=none "$DEST_APP" >/dev/null
codesign --verify --deep --strict --verbose=4 "$DEST_APP"

DMG_STAGE="$(mktemp -d "$DMG_STAGE_TEMPLATE")"
DMG_SETTINGS="$DMG_STAGE/dmgbuild-settings.py"
DEST_DMG_BACKGROUND="$DMG_STAGE/background.png"
cleanup() {
  rm -rf "$DMG_STAGE"
}
trap cleanup EXIT

find_python_module() {
  module="$1"
  shift || true
  for candidate in "${DEFCOIN_NU_PACKAGING_PYTHON:-}" /opt/local/bin/python3 /usr/local/bin/python3 /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 /opt/homebrew/bin/python3 /usr/bin/python3 "$(command -v python3 2>/dev/null || true)"; do
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
  "$PYTHON_PIL" - "$DEST_DMG_BACKGROUND" "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" "$PRODUCT_NAME" "$WORDMARK_THIRD_LINE" <<'PY'
import os
import sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

out_path, logo_path, product_name, third_line = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
width, height, scale = 640, 420, 2
rw, rh = width * scale, height * scale
base = Image.new("RGBA", (rw, rh), (18, 7, 28, 255))
draw = ImageDraw.Draw(base, "RGBA")

for y in range(rh):
    t = y / max(rh - 1, 1)
    r = int(18 + 15 * t)
    g = int(7 + 6 * t)
    b = int(28 + 18 * t)
    draw.line([(0, y), (rw, y)], fill=(r, g, b, 255))

for x in range(-rh, rw + rh, 28 * scale):
    draw.line([(x, 0), (x + 188 * scale, rh)], fill=(246, 246, 242, 20), width=1)
    draw.line([(x, rh), (x + 188 * scale, 0)], fill=(84, 42, 132, 32), width=1)
for x in range(0, rw, 24 * scale):
    for y in range(0, rh, 24 * scale):
        draw.ellipse([x, y, x + 1 * scale, y + 1 * scale], fill=(246, 246, 242, 22))

def blurred_ellipse(size, center, radius, color, blur):
    pad = (radius + blur + 4) * scale
    layer = Image.new("RGBA", (rw + pad * 2, rh + pad * 2), (0, 0, 0, 0))
    layer_draw = ImageDraw.Draw(layer, "RGBA")
    cx = center[0] * scale + pad
    cy = center[1] * scale + pad
    rr = radius * scale
    layer_draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur * scale))
    return layer.crop((pad, pad, pad + rw, pad + rh))

def alpha_composite_clipped(dst, src, x, y):
    x0 = max(0, x)
    y0 = max(0, y)
    x1 = min(dst.width, x + src.width)
    y1 = min(dst.height, y + src.height)
    if x1 <= x0 or y1 <= y0:
        return
    crop = src.crop((x0 - x, y0 - y, x1 - x, y1 - y))
    dst.alpha_composite(crop, (x0, y0))

purple_glow = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
for radius, alpha in [(360, 54), (275, 62), (205, 64), (135, 54)]:
    purple_glow.alpha_composite(blurred_ellipse((rw, rh), (-74, -22), radius, (92, 41, 138, alpha), 40))
base.alpha_composite(purple_glow)

if os.path.exists(logo_path):
    logo = Image.open(logo_path).convert("RGBA")
    logo = ImageEnhance.Contrast(logo).enhance(1.05)
    logo.thumbnail((292 * scale, 292 * scale), Image.Resampling.LANCZOS)
    coin_x = -72 * scale
    coin_y = -28 * scale
    coin_layer = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
    alpha_composite_clipped(coin_layer, logo, coin_x, coin_y)
    glow_alpha = coin_layer.getchannel("A").filter(ImageFilter.GaussianBlur(58 * scale))
    glow_layer = Image.new("RGBA", (rw, rh), (215, 196, 62, 0))
    glow_layer.putalpha(glow_alpha.point(lambda p: int(p * 0.14)))
    base.alpha_composite(glow_layer)
    # Keep the coin stack clearly in the corner and away from the app icon.
    alpha_composite_clipped(base, logo, coin_x, coin_y)

def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Avenir Next Condensed.ttc",
        "/System/Library/Fonts/Supplemental/Avenir Next Condensed.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Helvetica.ttf",
    ]
    for path in candidates:
        if path and os.path.exists(path):
            return ImageFont.truetype(path, size * scale)
    return ImageFont.load_default()

def ui_font(size):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Helvetica.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size * scale)
    return ImageFont.load_default()

title_font = font(58, True)
subtitle_font = ui_font(15)

def draw_logo_wordmark(draw, x, y, fill, shadow=None):
    # Mirrors main.cpp splash construction: Avenir Next Condensed ExtraBold,
    # absolute letter spacing 1.15, DEF + COIN as separate runs with a 2 px join.
    letter_spacing = 1.15 * scale
    join_gap = 2 * scale
    line_gap = 50 * scale
    def draw_spaced(text, tx, ty, color, spacing=letter_spacing):
        cursor = tx
        for ch in text:
            draw.text((cursor, ty), ch, font=title_font, fill=color)
            cursor += draw.textlength(ch, font=title_font) + spacing
        return cursor
    def measure_spaced(text, spacing=letter_spacing):
        if not text:
            return 0
        return sum(draw.textlength(ch, font=title_font) for ch in text) + spacing * max(0, len(text) - 1)
    core_width = measure_spaced("CORE NU")
    coin_width = measure_spaced("COIN")
    def_width = measure_spaced("DEF")
    target_width = max(def_width + join_gap + coin_width, core_width)
    if third_line and len(third_line) > 1:
        third_base_width = measure_spaced(third_line, 0)
        third_spacing = max(0, (target_width - third_base_width) / (len(third_line) - 1))
    else:
        third_spacing = letter_spacing
    third_width = measure_spaced(third_line, third_spacing)
    def draw_lines(offset_x, offset_y, color):
        draw_spaced("DEF", x + offset_x, y + offset_y, color)
        draw_spaced("COIN", x + offset_x + def_width + join_gap, y + offset_y, color)
        draw_spaced("CORE NU", x + offset_x, y + line_gap + offset_y, color)
        if third_line:
            draw_spaced(third_line, x + offset_x, y + (line_gap * 2) + offset_y, color, third_spacing)
    if shadow:
        draw_lines(3 * scale, 3 * scale, shadow)
    draw_lines(0, 0, fill)
    return max(def_width + join_gap + coin_width, core_width, third_width)

word_x = 254 * scale
word_y = (34 if third_line else 58) * scale
draw_logo_wordmark(draw, word_x, word_y, (246, 246, 242, 255), (0, 0, 0, 110))

# Finder draws icon labels in dark text. Add quiet light label fields behind
# the text so names remain readable on the dark purple background. These
# backplates are derived from the icon centers and measured label bounds rather
# than hand-tuned rectangle centers, which keeps them aligned when labels change.
label_bg = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
label_draw = ImageDraw.Draw(label_bg, "RGBA")
label_font = ui_font(13)
FINDER_ICON_SIZE = 96
FINDER_LABEL_GAP = 10
FINDER_LABEL_PAD_X = 9
FINDER_LABEL_PAD_Y = 5

def finder_label_backplate(icon_center_x, icon_center_y, label):
    text_bbox = draw.textbbox((0, 0), label, font=label_font)
    text_width = (text_bbox[2] - text_bbox[0]) / scale
    text_anchor_x = icon_center_x - (text_width / 2) - (text_bbox[0] / scale)
    text_anchor_y = icon_center_y + (FINDER_ICON_SIZE / 2) + FINDER_LABEL_GAP - (text_bbox[1] / scale)
    actual_left = text_anchor_x + (text_bbox[0] / scale)
    actual_top = text_anchor_y + (text_bbox[1] / scale)
    actual_right = text_anchor_x + (text_bbox[2] / scale)
    actual_bottom = text_anchor_y + (text_bbox[3] / scale)
    min_width = 84 if label == "Applications" else 126
    rect_width = max(min_width, (actual_right - actual_left) + (FINDER_LABEL_PAD_X * 2))
    rect_center = (actual_left + actual_right) / 2
    return (
        int((rect_center - rect_width / 2) * scale),
        int((actual_top - FINDER_LABEL_PAD_Y) * scale),
        int((rect_center + rect_width / 2) * scale),
        int((actual_bottom + FINDER_LABEL_PAD_Y) * scale),
    )

for box in [
    finder_label_backplate(220, 250, f"{product_name}.app"),
    finder_label_backplate(512, 250, "Applications"),
]:
    label_draw.rounded_rectangle(box, radius=7 * scale, fill=(246, 246, 242, 174))
label_bg = label_bg.filter(ImageFilter.GaussianBlur(0.2 * scale))
base.alpha_composite(label_bg)

arrow_y = 250 * scale
arrow = [
    (286 * scale, arrow_y - 7 * scale),
    (406 * scale, arrow_y - 7 * scale),
    (406 * scale, arrow_y - 20 * scale),
    (440 * scale, arrow_y),
    (406 * scale, arrow_y + 20 * scale),
    (406 * scale, arrow_y + 7 * scale),
    (286 * scale, arrow_y + 7 * scale),
]
draw.polygon([(x + 3 * scale, y + 3 * scale) for x, y in arrow], fill=(0, 0, 0, 70))
draw.polygon(arrow, fill=(93, 169, 246, 232))

subtitle = "Drag to Applications"
subtitle_box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
subtitle_width = subtitle_box[2] - subtitle_box[0]
draw.text(((360 * scale) - (subtitle_width // 2), 197 * scale), subtitle, font=subtitle_font, fill=(220, 211, 236, 232))

solid = Image.new("RGBA", (rw, rh), (18, 7, 28, 255))
solid.alpha_composite(base)
base = solid
base = base.resize((width, height), Image.Resampling.LANCZOS)
os.makedirs(os.path.dirname(out_path), exist_ok=True)
base.save(out_path)
PY
else
  if command -v magick >/dev/null 2>&1; then
    if [ -n "$WORDMARK_THIRD_LINE" ]; then
      magick -size 640x420 gradient:'#12071c-#210d2e' \
        "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" -resize 292x292 -gravity NorthWest -geometry -72-28 -composite \
        -fill '#f6f6f2' -pointsize 58 -gravity NorthWest -annotate +254+34 'DEFCOIN' \
        -fill '#f6f6f2' -pointsize 58 -gravity NorthWest -annotate +254+84 'CORE NU' \
        -fill '#f6f6f2' -pointsize 58 -gravity NorthWest -annotate +254+134 "$WORDMARK_THIRD_LINE" \
        -fill '#dccfee' -pointsize 17 -gravity NorthWest -annotate +294+197 'Drag to Applications' \
        "$DEST_DMG_BACKGROUND"
    else
      magick -size 640x420 gradient:'#12071c-#210d2e' \
        "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" -resize 292x292 -gravity NorthWest -geometry -72-28 -composite \
        -fill '#f6f6f2' -pointsize 58 -gravity NorthWest -annotate +254+58 'DEFCOIN' \
        -fill '#f6f6f2' -pointsize 58 -gravity NorthWest -annotate +254+108 'CORE NU' \
        -fill '#dccfee' -pointsize 17 -gravity NorthWest -annotate +294+197 'Drag to Applications' \
        "$DEST_DMG_BACKGROUND"
    fi
  else
    cp -p "$SCRIPT_DIR/../assets/brand/defcoin-nu-coin-stack-hires.png" "$DEST_DMG_BACKGROUND"
  fi
fi

ditto "$DEST_APP" "$DMG_STAGE/${PRODUCT_NAME}.app"
ln -s /Applications "$DMG_STAGE/Applications"
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
    '${PRODUCT_NAME}.app': (220, 250),
    'Applications': (512, 250),
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

touch -ch "$RELEASE_DIR" "$DEST_PLATFORM_DIR" "$DEST_APP" "$DEST_DMG"

if command -v SetFile >/dev/null 2>&1; then
  FINDER_DATE="$(date '+%m/%d/%Y %H:%M:%S')"
  for path in "$RELEASE_DIR" "$DEST_PLATFORM_DIR" "$DEST_APP" "$DEST_DMG"; do
    SetFile -d "$FINDER_DATE" "$path" >/dev/null 2>&1 || true
    SetFile -m "$FINDER_DATE" "$path" >/dev/null 2>&1 || true
  done
fi

echo "staged app: $DEST_APP"
echo "staged dmg: $DEST_DMG"
