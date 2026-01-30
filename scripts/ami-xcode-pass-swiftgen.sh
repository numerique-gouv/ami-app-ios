#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
mkdir AMI/Sources/Generated
if command -v swiftgen >/dev/null 2>&1; then
    swiftgen config run --config Tools/SwiftGen/swiftgen-ami-config.yml
else
    echo "warning: SwiftGen not installed, download from https://github.com/SwiftGen/SwiftGen"
fi