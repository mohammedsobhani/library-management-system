#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${API_BASE_URL:-}" ]]; then
  echo "Set API_BASE_URL in the Vercel project environment variables." >&2
  exit 1
fi

flutter_version="${FLUTTER_VERSION:-3.38.9}"

if ! command -v flutter >/dev/null 2>&1; then
  flutter_home="${HOME}/.cache/flutter-${flutter_version}"
  if [[ ! -x "${flutter_home}/bin/flutter" ]]; then
    mkdir -p "$(dirname "${flutter_home}")"
    git clone --depth 1 --branch "${flutter_version}" \
      https://github.com/flutter/flutter.git "${flutter_home}"
  fi
  export PATH="${flutter_home}/bin:${PATH}"
fi

flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define="API_BASE_URL=${API_BASE_URL%/}"
