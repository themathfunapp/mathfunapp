#!/usr/bin/env bash
# macOS: App Store IPA with obfuscation. Run from repo root: bash scripts/build_release_ipa.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SYM="$ROOT/symbols/ios"
rm -rf "$SYM"
mkdir -p "$SYM"
flutter build ipa --release --obfuscate --split-debug-info="$SYM"
echo "IPA build done. Symbol maps (backup securely, do not commit): $SYM"
