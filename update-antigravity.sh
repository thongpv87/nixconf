#!/usr/bin/env bash
# Script to auto-update Antigravity IDE version in Nix configuration

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_FILE="$DIR/overlays/antigravity-version.json"

if [ -n "$1" ]; then
    URL="$1"
    VERSION="${2:-manual-update}"
    echo "Downloading and calculating hash for $URL..."
    HASH=$(nix-prefetch-url "$URL")
    if [ -z "$HASH" ]; then
        echo "Failed to fetch hash"
        exit 1
    fi
    echo "{\"version\": \"$VERSION\", \"url\": \"$URL\", \"sha256\": \"$HASH\"}" > "$JSON_FILE"
    git add "$JSON_FILE"
    echo "Done! Run 'sudo nixos-rebuild switch' to apply."
    exit 0
fi

echo "Fetching latest Antigravity IDE version..."
INFO=$(curl -s "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest")

if [ -z "$INFO" ]; then
    echo "Error: Failed to fetch update info from API."
    exit 1
fi

URL=$(echo "$INFO" | jq -r '.url' | sed 's/ /%20/g')
SHA256=$(echo "$INFO" | jq -r '.sha256hash')
VERSION=$(echo "$URL" | grep -oP '/antigravity/stable/\K[\d.]+')

if [ -z "$URL" ] || [ -z "$SHA256" ] || [ -z "$VERSION" ]; then
    echo "Error: Failed to parse update info."
    exit 1
fi

echo "Latest version found: $VERSION"

cat > "$JSON_FILE" <<EOF
{
  "version": "$VERSION",
  "url": "$URL",
  "sha256": "$SHA256"
}
EOF

echo "Saved to $JSON_FILE."
git add "$JSON_FILE"
echo "You can now run 'sudo nixos-rebuild switch' to apply the update!"
