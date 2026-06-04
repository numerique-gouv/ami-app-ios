#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if command -v sourcery >/dev/null 2>&1; then
    sourcery
else
    echo "warning: Sourcery not installed, download from https://github.com/krzysztofzablocki/Sourcery"
fi