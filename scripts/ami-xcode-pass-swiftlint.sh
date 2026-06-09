#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if command -v swiftlint >/dev/null 2>&1; then
# auto-fix trailing whitespaces warnings first.
    swiftlint --fix --only-rule trailing_whitespace && swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi