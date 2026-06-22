#!/bin/bash
# Patch Samsung Health 6.32 for Knox-tripped Samsung phones (full Mac/PC flow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APK="${1:-$ROOT/originals/shealth.apk}"
APP="$(basename "$APK" .apk)"

if [[ ! -f "$APK" ]]; then
  echo "APK not found: $APK" >&2
  echo "Usage: $0 [path/to/shealth.apk]" >&2
  exit 1
fi

for cmd in apktool zipalign apksigner; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Missing $cmd (install Android build-tools / apktool)" >&2
    exit 1
  fi
done

mkdir -p "$ROOT/patched" "$ROOT/decompiled"

echo "==> Decompile $APP"
apktool d -f "$APK" -o "$ROOT/decompiled/$APP"

echo "==> Samsung Account workaround (com.notsamsung.dummy)"
# shellcheck source=scripts/sed-inplace.sh
source "$ROOT/scripts/sed-inplace.sh"
while IFS= read -r -d '' f; do
  sed_inplace 's/com\.osp\.app\.signin/com.notsamsung.dummy/g' "$f"
done < <(find "$ROOT/decompiled/$APP" -type f \( -name '*.smali' -o -name '*.xml' \) -print0)

echo "==> Knox bypass"
python3 "$ROOT/patches/apply_shealth_knox_bypass.py"

echo "==> Rebuild"
apktool b "$ROOT/decompiled/$APP" --use-aapt2
OUT="$ROOT/decompiled/$APP/dist/$APP.apk"
ALIGNED="$ROOT/patched/$APP.apk"
zipalign -f -p 4 "$OUT" "$ALIGNED"

echo "==> Sign (SamsungPatch keystore)"
apksigner sign --ks "$ROOT/keystore.jks" --ks-pass "file:$ROOT/ks-pass.txt" "$ALIGNED"

echo "==> Done: $ALIGNED"
apksigner verify --print-certs "$ALIGNED" | head -5
