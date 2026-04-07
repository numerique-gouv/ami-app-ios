## SwiftUIWebView
It is just a SwiftUI wrapper over:
- a **WKWebView** 
- its View Model **SwiftUIWebView.ViewModel**.

---

## SwiftUIWebView.ViewModel
The **SwiftUIWebView.ViewModel** is initialized with:
- a **WKWebViewConfiguration** that enable any new SwiftUIWebView to have it's own Data Storage. By default, they all share a common persistent Data Storage.
- a root url
- a **WebViewDelegate** instance that called simple events
- a **WebViewUserScripts** instance fulfilling **WebViewUserScriptsProtocol** that enable any new SwiftUIWebView to inject its own user scripts
- **allowsBackForwardNavigationGestures** boolean that activates swipe back gesture if wanted (default to TRUE)
- **acceptSelfSignedCertificate** boolean that activates the usage of self-signed certificates (for development tests for instance). Default to FALSE
- a **urlChangeAction** instance called when the url of the webView change

---

## WebViewDelegate
A protocol requiring the following simple methods:
- func **navigationWillStart**(navigationAction: WKNavigationAction)
- func **navigationDidStart**()
- func **navigationDidFinish**()
- func **navigationDidFailed**(withError error: Error)

---

## WebViewUserScriptsProtocol
A protocol requiring:
- a list of **UserScripts** defined as follow:
	- name: String
    - script: WKUserScript
- a method implementation **userScriptEmittedMessage** calledc when a script is triggered.

---

## AMIWebView
It is just a **preconfigured SwiftUIWebView** with:
- a loading bar
- a custom back button.

---

## HomeView - *a simple usage of all of this*
With all of this, **HomeView** is a SwiftUI view containing:
- an **AMIWebView**
- **viewModel**: a HomeView.ViewModel containing:
  - **webViewViewModel**: a SwiftUIWebView.ViewModel for the AMIWebView
  - its own local properties to handle its local state
  - the **handleUrlChange** callback
  - **HomeViewDelegate**: a simple WebViewDelegate that log navigation steps
  - a **HomeUserScripts** instance that handle user scripts injected in HomeView
