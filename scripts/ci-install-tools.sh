#!/usr/bin/env bash
# Install apktool + Android build-tools on Ubuntu CI runners.
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-/usr/local/lib/android/sdk}"
export ANDROID_HOME
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

if ! command -v apktool >/dev/null; then
  APKTOOL_VERSION="${APKTOOL_VERSION:-2.9.3}"
  curl -fsSL "https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool/apktool" -o /usr/local/bin/apktool
  curl -fsSL "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar" -o /usr/local/bin/apktool.jar
  chmod +x /usr/local/bin/apktool /usr/local/bin/apktool.jar
fi

if ! command -v sdkmanager >/dev/null; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip
  unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-unpack
  mv /tmp/cmdline-tools-unpack/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
fi

yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "build-tools;34.0.0"
export PATH="$ANDROID_HOME/build-tools/34.0.0:$ANDROID_HOME/platform-tools:$PATH"

for cmd in apktool zipalign apksigner python3 patch; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd after setup" >&2; exit 1; }
done

echo "apktool: $(apktool --version | head -1)"
echo "zipalign: $(command -v zipalign)"
echo "apksigner: $(command -v apksigner)"
