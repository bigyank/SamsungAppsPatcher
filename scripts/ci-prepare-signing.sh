#!/usr/bin/env bash
# Restore signing keystore + password file from GitHub Actions secrets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -n "${KEYSTORE_JKS_B64:-}" ]]; then
  echo "$KEYSTORE_JKS_B64" | base64 -d > keystore.jks
  chmod 600 keystore.jks
elif [[ -f keystore.jks ]]; then
  echo "Using existing keystore.jks"
else
  echo "No keystore: set KEYSTORE_JKS_B64 secret or place keystore.jks in repo root" >&2
  exit 1
fi

STORE_PASS="${KEYSTORE_STORE_PASS:-${KEYSTORE_PASS:-}}"
KEY_PASS="${KEYSTORE_KEY_PASS:-$STORE_PASS}"

if [[ -n "$STORE_PASS" ]]; then
  printf '%s\n%s\n' "$STORE_PASS" "$KEY_PASS" > ks-pass.txt
  chmod 600 ks-pass.txt
elif [[ -f ks-pass.txt ]]; then
  echo "Using existing ks-pass.txt"
else
  echo "No keystore password: set KEYSTORE_STORE_PASS secret or ks-pass.txt" >&2
  exit 1
fi

keytool -list -keystore keystore.jks -storepass "$STORE_PASS" >/dev/null 2>&1 || {
  echo "Keystore invalid or password wrong" >&2
  exit 1
}

echo "Signing material ready"
