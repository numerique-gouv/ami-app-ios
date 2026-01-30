#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if command -v swiftformat >/dev/null 2>&1; then
    swiftformat --lint --lenient "$PROJECT_DIR"
else
    echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi