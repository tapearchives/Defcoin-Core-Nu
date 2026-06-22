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
if [[ "$BUILT_APP_BASENAME" != "DefcoinCoreNu.app" && "$BUILT_APP_BASENAME" != "Defcoin Core Nu.app" ]]; then
  echo "only Defcoin Core Nu app bundles can be staged by this script" >&2
  exit 2
fi
PRODUCT_NAME="Defcoin Core Nu"
PRODUCT_SLUG="Defcoin-Core-Nu"
APP_EXECUTABLE_NAME="DefcoinCoreNu"
DEST_DMG_BACKGROUND_BASENAME="defcoin-core-nu-dmg-background.png"
DMG_STAGE_TEMPLATE="/tmp/defcoin-nu-dmg-stage.XXXXXX"
WORDMARK_THIRD_LINE=""
LOCKUP_ASSET_BASENAME="defcoin-core-nu-lockup.png"
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
find "$NU_RESOURCE_DIR/qml" -type f -name '*.agent.md' -delete 2>/dev/null || true
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
APP_EXE="$DEST_APP/Contents/MacOS/$APP_EXECUTABLE_NAME"

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

app_executable_uses_bundled_qt() {
  [ -x "$APP_EXE" ] || return 1
  otool -L "$APP_EXE" | awk '
    /Qt[A-Za-z0-9_]*\.framework/ {
      if ($1 !~ /^@rpath\// && $1 !~ /^@executable_path\//) {
        bad = 1
      }
    }
    END { exit bad ? 1 : 0 }
  '
}

if [ -z "${DEFCOIN_NU_QT_ROOT:-}" ] \
  && [ -d "$DEST_APP/Contents/Frameworks/QtCore.framework" ] \
  && [ -f "$DEST_APP/Contents/PlugIns/platforms/libqcocoa.dylib" ] \
  && app_executable_uses_bundled_qt; then
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
  "$PYTHON_PIL" - "$DEST_DMG_BACKGROUND" "$SCRIPT_DIR/../assets/brand/$LOCKUP_ASSET_BASENAME" "$PRODUCT_NAME" "$WORDMARK_THIRD_LINE" <<'PY'
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

out_path, lockup_path, product_name, third_line = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
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

if os.path.exists(lockup_path):
    lockup = Image.open(lockup_path).convert("RGBA")
    target_wordmark_size = 35 if third_line else 44
    lockup_scale = target_wordmark_size / 256.0
    lockup_size = (int(lockup.width * lockup_scale * scale), int(lockup.height * lockup_scale * scale))
    lockup = lockup.resize(lockup_size, Image.Resampling.LANCZOS)
    lockup_x = int((width * scale - lockup.width) / 2)
    lockup_y = (16 if third_line else 30) * scale
    base.alpha_composite(lockup, (lockup_x, lockup_y))

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
APP_ICON_CENTER_X = 188
APPLICATIONS_ICON_CENTER_X = 452
INSTALL_ROW_CENTER_X = 320
INSTALL_ICON_CENTER_Y = 258

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
    finder_label_backplate(APP_ICON_CENTER_X, INSTALL_ICON_CENTER_Y, f"{product_name}.app"),
    finder_label_backplate(APPLICATIONS_ICON_CENTER_X, INSTALL_ICON_CENTER_Y, "Applications"),
]:
    label_draw.rounded_rectangle(box, radius=7 * scale, fill=(246, 246, 242, 174))
label_bg = label_bg.filter(ImageFilter.GaussianBlur(0.2 * scale))
base.alpha_composite(label_bg)

arrow_y = INSTALL_ICON_CENTER_Y * scale
arrow = [
    (252 * scale, arrow_y - 7 * scale),
    (382 * scale, arrow_y - 7 * scale),
    (382 * scale, arrow_y - 20 * scale),
    (418 * scale, arrow_y),
    (382 * scale, arrow_y + 20 * scale),
    (382 * scale, arrow_y + 7 * scale),
    (252 * scale, arrow_y + 7 * scale),
]
draw.polygon([(x + 3 * scale, y + 3 * scale) for x, y in arrow], fill=(0, 0, 0, 70))
draw.polygon(arrow, fill=(93, 169, 246, 232))

subtitle = "Drag to Applications"
subtitle_box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
subtitle_width = subtitle_box[2] - subtitle_box[0]
draw.text(((INSTALL_ROW_CENTER_X * scale) - (subtitle_width // 2), 200 * scale), subtitle, font=subtitle_font, fill=(220, 211, 236, 232))

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
        "$SCRIPT_DIR/../assets/brand/$LOCKUP_ASSET_BASENAME" -resize 226x -gravity North -geometry +0+16 -composite \
        -fill '#dccfee' -pointsize 17 -gravity North -annotate +0+200 'Drag to Applications' \
        "$DEST_DMG_BACKGROUND"
    else
      magick -size 640x420 gradient:'#12071c-#210d2e' \
        "$SCRIPT_DIR/../assets/brand/$LOCKUP_ASSET_BASENAME" -resize 284x -gravity North -geometry +0+30 -composite \
        -fill '#dccfee' -pointsize 17 -gravity North -annotate +0+200 'Drag to Applications' \
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
    '${PRODUCT_NAME}.app': (188, 258),
    'Applications': (452, 258),
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
