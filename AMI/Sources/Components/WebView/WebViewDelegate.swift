//
//  WebViewDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 19/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

protocol WebViewDelegate: AnyObject {
    func navigationWillStart(navigationAction: WKNavigationAction)

    func navigationDidStart()

    func navigationDidFinish()

    func navigationDidFailed(withError error: Error)
}

extension WebViewDelegate {
    // These default empty implementation makes the above methods optional to implement.
    func navigationWillStart(navigationAction: WKNavigationAction) {}
    func navigationDidStart() {}
    func navigationDidFinish() {}
    func navigationDidFailed(withError error: Error) {}
}

class WebViewDelegateSimulatorImplementation: WebViewDelegate {
    func navigationWillStart() {
        print("[WebViewDelegate] Navigation will start")
    }
    
    func navigationDidStart() {
        print("[WebViewDelegate] Navigation did start")
    }
    
    func navigationDidFinish() {
        print("[WebViewDelegate] Navigation did finish")
    }
    
    func navigationDidFailed(withError error: Error) {
        print("[WebViewDelegate] Navigation did failed with error: \(error)")
    }
}
