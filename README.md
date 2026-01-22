# AMI iOS app

This is the iOS app for https://github.com/numerique-gouv/ami-notifications-api

## Description

AMI Xcode project uses several tools:
- `XcodeGen` to genearte Xcode project: [https://github.com/yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen)
- `SwiftFormat` to format Swift code: [https://github.com/nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- `SwiftLint` to format Swift code: [https://github.com/realm/SwiftLint](https://github.com/realm/SwiftLint)
- `SwiftGen` to automatically generate Swift resources properies/methods: [https://github.com/SwiftGen/SwiftGen](https://github.com/SwiftGen/SwiftGen)

Xcode project `.xcodeproj` is not gitted to avoid a lot of conflicts when working in team on the project.
It is generated using `xcodegen` tool.

The project is described using 2 files:
- the Xcode project: ami-project.yml
- the Xcode targets: ami-targets.yml

## Start with the project

1. To configure your environnement, execute the script:
> scripts/ami-configure-build-tools.sh

2. To clone the project, use `git clone` command:
> git clone git@github.com:numerique-gouv/ami-app-ios.git
 
3. Then, generate the Xcode project using script:
> scripts/ami-generate-xcode.sh

4. Now, you can open the generated `AMI-xcodegen.xcodeproj` in Xcode.
> xed AMI-xcodegen.xcodeproj


