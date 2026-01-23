#!/bin/sh
# chmod +x ami-generate-xcode.sh

# Made with AI

function check_and_install_brew() {
    echo "Checking if Homebrew is installed..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "\tHomebrew is not installed. You can install it with the command: \"curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh\""
        return 1 # false
    else
        echo "\tHomebrew is already installed: $(brew --version)"
        return 0 # true
    fi
}

function check_and_install_xcodegen() {
    echo "Checking if XcodeGen is installed..."
    if ! command -v xcodegen >/dev/null 2>&1; then
        echo "\XcodeGen is not installed. Installing XcodeGen using Homebrew..."
        brew install xcodegen
    else
        echo "\tXcodeGen is already installed: $(xcodegen --version)"
    fi
}

function check_and_install_swiftformat() {
    echo "Checking if SwiftFormat is installed..."
    if ! command -v swiftformat >/dev/null 2>&1; then
        echo "\tSwiftFormat is not installed. Installing SwiftFormat using Homebrew..."
        brew install swiftformat
    else
        echo "\tSwiftFormat is already installed: $(swiftformat --version)"
    fi
}

function check_and_install_swiftlint() {
    echo "Checking if SwiftLint is installed..."
    if ! command -v swiftlint >/dev/null 2>&1; then
        echo "\tSwiftLint is not installed. Installing SwiftLint using Homebrew..."
        brew install swiftlint
    else
        echo "\tSwiftLint is already installed: $(swiftlint --version)"
    fi
}

function check_and_install_swiftgen() {
    echo "Checking if SwiftGen is installed..."
    if ! command -v swiftgen >/dev/null 2>&1; then
        echo "\tSwiftGen is not installed. Installing SwiftGen using Homebrew..."
        brew install swiftgen
    else
        echo "\tSwiftGen is already installed: $(swiftgen --version)"
    fi
}

function main() {
    if ! check_and_install_brew; then
        echo "Stopping configuration due to missing Homebrew."
        exit 1
    fi
    check_and_install_xcodegen
    check_and_install_swiftformat
    check_and_install_swiftlint
    check_and_install_swiftgen
}

main