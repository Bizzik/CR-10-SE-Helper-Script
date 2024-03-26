#!/bin/sh

GUPPY_DIR="/usr/data/guppyscreen"
CURL="/usr/data/helper-script/files/fixes/curl"
VERSION_FILE="$GUPPY_DIR/.version"
CUSTOM_UPGRADE_SCRIPT="$GUPPY_DIR/custom_upgrade.sh"

if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(jq -r '.version' "$VERSION_FILE")
    THEME=$(jq -r '.theme' "$VERSION_FILE")
    ASSET_NAME=$(jq '.asset_name' "$VERSION_FILE")
fi

"$CURL" -s https://api.github.com/repos/ballaswag/guppyscreen/releases -o /tmp/guppy-releases.json
latest_version=$(jq -r '.[0].tag_name' /tmp/guppy-releases.json)
if [ "$(printf '%s\n' "$CURRENT_VERSION" "$latest_version" | sort -V | head -n1)" = "$latest_version" ]; then 
    echo "Guppy Screen $CURRENT_VERSION is already up to date!"
    rm -f /tmp/guppy-releases.json
    exit 0
else
    asset_url=$(jq -r ".[0].assets[] | select(.name == $ASSET_NAME).browser_download_url" /tmp/guppy-releases.json)
    echo "Downloading latest version $latest_version from $asset_url"
    "$CURL" -L "$asset_url" -o /usr/data/guppyscreen.tar.gz
fi

tar -xvf /usr/data/guppyscreen.tar.gz -C "$GUPPY_DIR/.."

if [ -f "$CUSTOM_UPGRADE_SCRIPT" ]; then
    echo "Running custom_upgrade.sh for release $latest_version..."
    "$CUSTOM_UPGRADE_SCRIPT"
fi

echo "Guppy Screen have been updated to version $latest_version!"

if grep -Fqs "ID=buildroot" /etc/os-release
then
    [ -f /etc/init.d/S99guppyscreen ] && /etc/init.d/S99guppyscreen stop &> /dev/null
    killall -q guppyscreen
    /etc/init.d/S99guppyscreen restart &> /dev/null
    rm -f /usr/data/guppyscreen.tar.gz 
    rm -f /tmp/guppy-releases.json
fi

exit 0
