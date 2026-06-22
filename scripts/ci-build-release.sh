#!/usr/bin/env bash
# Download unpatched APKs from GitHub secrets and build patched release artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APPS="${BUILD_APPS:-shealth}"
mkdir -p originals patched release-artifacts

download_app() {
  local app="$1"
  local url_var
  url_var="$(python3 -c "import json; m=json.load(open('versions.json'))['apps']['$app']; print(m['apk_url_secret'])")"
  local url="${!url_var:-}"

  if [[ -z "$url" ]]; then
    echo "Skip $app: secret $url_var not set" >&2
    return 1
  fi

  echo "==> Download $app from $url_var"
  curl -fL --retry 3 --retry-delay 5 -o "originals/${app}.apk" "$url"
  local size
  size="$(wc -c < "originals/${app}.apk" | tr -d ' ')"
  if [[ "$size" -lt 1000000 ]]; then
    echo "Download too small for $app ($size bytes) — check $url_var" >&2
    exit 1
  fi
}

patch_app() {
  local app="$1"
  local script version artifact template out

  script="$(python3 -c "import json; print(json.load(open('versions.json'))['apps']['$app']['patch_script'])")"
  version="$(python3 -c "import json; print(json.load(open('versions.json'))['apps']['$app']['version'])")"
  template="$(python3 -c "import json; print(json.load(open('versions.json'))['apps']['$app']['artifact_name'])")"
  artifact="${template//\{version\}/$version}"
  out="release-artifacts/$artifact"

  echo "==> Patch $app via $script"
  case "$script" in
    patch-shealth-632.sh)
      bash "$ROOT/patch-shealth-632.sh" "originals/${app}.apk"
      cp "patched/${app}.apk" "$out"
      ;;
    wearable-patcher.sh)
      bash "$ROOT/wearable-patcher.sh" -f "$app"
      cp "patched/${app}.apk" "$out"
      ;;
    *)
      echo "Unknown patch script: $script" >&2
      exit 1
      ;;
  esac

  apksigner verify --verbose "$out" >/dev/null
  echo "Built $out ($(wc -c < "$out" | tr -d ' ') bytes)"
}

built=0
for app in $APPS; do
  if download_app "$app"; then
    patch_app "$app"
    built=$((built + 1))
  fi
done

if [[ "$built" -eq 0 ]]; then
  echo "No APKs built. Set at least one *_APK_URL secret (see OBTAINIUM.md)." >&2
  exit 1
fi

echo "==> Release artifacts"
ls -lh release-artifacts/
