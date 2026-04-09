//
//  NativeRoutes.swift
//  AMI
//

enum NativeRoute {
    case settings
}

let nativeRoutes: [String: NativeRoute] = [
    "/#/settings": .settings
]

func findNativeRoute(for url: String) -> NativeRoute? {
    nativeRoutes.first { (path, _) in url.contains(path) }?.value
}
