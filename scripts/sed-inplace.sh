#!/usr/bin/env bash
# Portable sed -i for GNU (Linux/CI) and BSD (macOS).
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}
