#!/usr/bin/env bash
# Build a Release BmadBrowser.app, Developer ID sign with Hardened Runtime,
# notarize via Apple, staple the ticket, and package it as a distributable .dmg.
#
# Usage: ./Scripts/release.sh <version>
#   e.g. ./Scripts/release.sh 1.0.0
#
# Prerequisites (one-time setup — already satisfied on this Mac, see MEMORY.md):
#   - "Developer ID Application: Vincent LAURIAT (KFLACS69T9)" certificate in
#     the login keychain.
#   - notarytool credentials stored under the shared keychain profile
#     "AppliMacVincentGithub" (same Apple ID/team across Vincent's apps). Only
#     needed again if revoked:
#       xcrun notarytool store-credentials "AppliMacVincentGithub" \
#         --apple-id "vincent@lauriat.fr" --team-id "KFLACS69T9"
#
# Override defaults if needed:
#   SIGNING_IDENTITY="Developer ID Application: …" ./Scripts/release.sh 1.0.0
#   NOTARY_PROFILE="AppliMacVincentGithub"         ./Scripts/release.sh 1.0.0
#
# Local dry run (build + sign + DMG, no notarization):
#   SKIP_NOTARIZE=1 ./Scripts/release.sh 1.0.0
#
# Outputs release/BmadBrowser-<version>.dmg, fully notarized & stapled.

set -euo pipefail

VERSION="${1:?Usage: ./Scripts/release.sh <version>  (e.g. ./Scripts/release.sh 1.0.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1. Sanity check: project.yml must declare the same MARKETING_VERSION
if ! grep -q "MARKETING_VERSION: \"$VERSION\"" project.yml; then
  echo "✗ MARKETING_VERSION in project.yml does not match $VERSION" >&2
  grep "MARKETING_VERSION" project.yml | sed 's/^/    /' >&2
  echo "  Bump project.yml first, then re-run." >&2
  exit 1
fi

# 2. Regenerate xcodeproj
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "✗ XcodeGen not installed. brew install xcodegen" >&2
  exit 1
fi
echo "→ xcodegen generate"
xcodegen generate >/dev/null

# 3. Build Release (signing done manually afterwards — Release codesign in
#    xcodebuild often fails on com.apple.provenance xattrs set by lsregister)
echo "→ xcodebuild Release"
xcodebuild -project BmadBrowser.xcodeproj \
  -scheme BmadBrowser \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tail -5

APP="$ROOT/build/Build/Products/Release/BmadBrowser.app"
if [ ! -d "$APP" ]; then
  echo "✗ Build did not produce $APP" >&2
  exit 1
fi

SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Vincent LAURIAT (KFLACS69T9)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AppliMacVincentGithub}"

# 4. Stage to a clean directory (strips xattrs that break in-place codesign)
STAGING_DIR="$(mktemp -d)"
STAGING="$STAGING_DIR/BmadBrowser.app"
echo "→ Staging to $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

# codesign helper with retry (Apple timestamp server is occasionally flaky)
codesign_ts() {
  local target="$1"
  local attempt
  for attempt in 1 2 3 4 5; do
    if codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target" 2>&1; then
      return 0
    fi
    if [ "$attempt" -lt 5 ]; then
      echo "  ↻ codesign failed (attempt $attempt/5), retrying in 5s…"
      sleep 5
    fi
  done
  echo "✗ codesign $target failed after 5 attempts" >&2
  return 1
}

# 5. Sign nested frameworks first (deepest → outermost), then the app.
echo "→ Codesigning bundled frameworks"
if [ -d "$STAGING/Contents/Frameworks" ]; then
  # dylibs first
  find "$STAGING/Contents/Frameworks" -type f -name "*.dylib" | while read -r dylib; do
    codesign_ts "$dylib"
  done
  # then .framework bundles
  find "$STAGING/Contents/Frameworks" -maxdepth 1 -type d -name "*.framework" | while read -r fw; do
    codesign_ts "$fw"
  done
fi

echo "→ Codesigning the app itself with Developer ID + Hardened Runtime"
codesign_ts "$STAGING"
codesign --verify --strict --deep "$STAGING"

# 6. Package the signed app into a DMG (with an /Applications alias for drag-install)
RELEASE_DIR="$ROOT/release"
mkdir -p "$RELEASE_DIR"
DMG="$RELEASE_DIR/BmadBrowser-$VERSION.dmg"
rm -f "$DMG"

DMG_SRC="$(mktemp -d)"
ditto "$STAGING" "$DMG_SRC/BmadBrowser.app"
ln -s /Applications "$DMG_SRC/Applications"

echo "→ Creating $DMG"
hdiutil create -volname "BmadBrowser" -srcfolder "$DMG_SRC" -ov -format UDZO "$DMG" >/dev/null

# 7. Notarize + staple (skippable for a local dry run)
if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
  echo "⚠ SKIP_NOTARIZE=1 — DMG signed but NOT notarized: $DMG"
  exit 0
fi

echo "→ Submitting to Apple notary (this can take a few minutes)…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "→ Stapling ticket"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo ""
echo "✓ Done: $DMG"
echo "  Verify independently:"
echo "    spctl -a -t open --context context:primary-signature -vv \"$DMG\""
echo "    codesign --verify --deep --strict \"$STAGING\""
