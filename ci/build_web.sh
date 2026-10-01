#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.7.1"
GODOT_STATUS="stable"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/theodore-ball-godot-${GODOT_VERSION}"
GODOT_DIR="$CACHE_ROOT/editor"
GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.${GODOT_STATUS}"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_STATUS}/Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64.zip"
TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_STATUS}/Godot_v${GODOT_VERSION}-${GODOT_STATUS}_export_templates.tpz"
OUT="$ROOT/game/mobile_web"

mkdir -p "$GODOT_DIR" "$TEMPLATE_DIR" "$OUT"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Downloading official Godot ${GODOT_VERSION} Linux editor..."
  tmp_zip="$(mktemp --suffix=.zip)"
  curl -L --fail --retry 4 --retry-delay 2 -o "$tmp_zip" "$GODOT_URL"
  python3 - "$tmp_zip" "$GODOT_DIR" <<'PY'
import sys, zipfile
from pathlib import Path
src, dst = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(src) as zf:
    zf.extractall(dst)
PY
  rm -f "$tmp_zip"
  chmod +x "$GODOT_BIN"
fi

if [[ ! -s "$TEMPLATE_DIR/web_nothreads_release.zip" || ! -s "$TEMPLATE_DIR/web_nothreads_debug.zip" ]]; then
  echo "Installing the official Godot ${GODOT_VERSION} no-threads Web export templates..."
  python3 "$ROOT/ci/fetch_godot_web_template.py" "$TEMPLATES_URL" "$TEMPLATE_DIR"
fi

"$GODOT_BIN" --version
rm -rf "$OUT"
mkdir -p "$OUT"

# Godot Web mobile texture export validation requires ETC2/ASTC source imports.
# Apply this only to the ephemeral CI working copy; gameplay/project source stays unchanged.
python3 - "$ROOT/project.godot" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
setting = "textures/vram_compression/import_etc2_astc=true"
if setting not in text:
    marker = "[rendering]\n"
    if marker not in text:
        raise SystemExit("ERROR: [rendering] section missing from project.godot")
    text = text.replace(marker, marker + "\n" + setting + "\n", 1)
    p.write_text(text, encoding="utf-8")
    print("Enabled ETC2/ASTC texture imports for Mobile Web export working copy.")
PY

# Import source assets first. The mobile project was specifically made to parse without GodotSteam.
echo "Importing Godot project resources..."
"$GODOT_BIN" --headless --path "$ROOT" --import

echo "Exporting Theodore Ball Mobile Web PWA..."
"$GODOT_BIN" --headless --path "$ROOT" --export-release "Mobile Web PWA" "$OUT/index.html"

[[ -s "$OUT/index.html" ]] || { echo "ERROR: index.html was not generated" >&2; exit 1; }
find "$OUT" -maxdepth 1 -type f -printf '%f %s bytes\n' | sort

# Vercel/Git hosting must serve this directory over HTTPS for installable iPhone PWA behavior.
echo "WEB_BUILD_OUTPUT=$OUT"
