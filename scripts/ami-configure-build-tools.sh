#!/bin/sh
# chmod +x ami-generate-xcode.sh

# Made with AI

check_and_install_brew() {
    echo "Checking if Homebrew is installed..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "\tHomebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "\tHomebrew is already installed: $(brew --version)"
    fi
}

check_and_install_swiftformat() {
    echo "Checking if SwiftFormat is installed..."
    if ! command -v swiftformat >/dev/null 2>&1; then
        echo "\tSwiftFormat is not installed. Installing SwiftFormat using Homebrew..."
        brew install swiftformat
    else
        echo "\tSwiftFormat is already installed: $(swiftformat --version)"
    fi
}

check_and_install_swiftlint() {
    echo "Checking if SwiftLint is installed..."
    if ! command -v swiftlint >/dev/null 2>&1; then
        echo "\tSwiftLint is not installed. Installing SwiftLint using Homebrew..."
        brew install swiftlint
    else
        echo "\tSwiftLint is already installed: $(swiftlint --version)"
    fi
}

check_and_install_swiftgen() {
    echo "Checking if SwiftGen is installed..."
    if ! command -v swiftgen >/dev/null 2>&1; then
        echo "\tSwiftGen is not installed. Installing SwiftGen using Homebrew..."
        brew install swiftgen
    else
        echo "\tSwiftGen is already installed: $(swiftgen --version)"
    fi
}

# Main script execution
check_and_install_brew
check_and_install_swiftformat
check_and_install_swiftlint
check_and_install_swiftgen