#!/usr/bin/env bash
set -euo pipefail

# Netlify's build image does not ship the Flutter SDK, and `git clone` is
# disabled in this sandbox, so this script downloads the official prebuilt
# Flutter SDK archive (resolving the current stable release dynamically so
# it stays compatible with this project's `sdk: ^3.11.1` constraint).
FLUTTER_DIR="$HOME/flutter"

RELEASES_JSON_FILE="/tmp/flutter_releases_linux.json"
curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json -o "$RELEASES_JSON_FILE"
read -r FLUTTER_VERSION_STR ARCHIVE_PATH <<< "$(node -e '
  const fs = require("fs");
  const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const stableHash = data.current_release.stable;
  const release = data.releases.find((r) => r.hash === stableHash && r.channel === "stable");
  if (!release) process.exit(1);
  console.log(release.version, release.archive);
' "$RELEASES_JSON_FILE")"

if [ -z "$ARCHIVE_PATH" ] || [ -z "$FLUTTER_VERSION_STR" ]; then
  echo "Failed to resolve latest stable Flutter release" >&2
  exit 1
fi

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION_STR} (stable channel)..."
  FLUTTER_TAR="/tmp/flutter.tar.xz"
  curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE_PATH}" -o "$FLUTTER_TAR"
  tar -xJf "$FLUTTER_TAR" -C "$HOME"
fi

# This sandbox blocks the git subcommands (`git -c ...`, `git ls-remote`)
# that the Flutter tool normally uses to determine the SDK version from the
# bundled `.git` metadata. Without a resolvable version, `flutter pub get`
# reports the SDK as "0.0.0-unknown" and rejects any package (e.g.
# google_mobile_ads) that declares a minimum Flutter SDK constraint. Writing
# the plain-text `version` file at the SDK root is the Flutter tool's
# documented fallback for environments where git-based detection isn't
# available, so pin it explicitly to the version we just downloaded.
echo "${FLUTTER_VERSION_STR#v}" > "$FLUTTER_DIR/version"

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release
