# UrlInterception

Rewrites navigated URLs before a `WKWebView` loads them: when the URL host matches a
rule's regex, missing query parameters are added. Headless and stateless — the host
web view degrades to "load as-is" for everything the feature doesn't explicitly claim.

## How it works

1. The host calls `rewriteUrl.rewrite(url:)` inside `decidePolicyFor` (tapped links + page redirects only).
2. `RewriteUrlUseCase` filters the static catalog by whole-host regex match (case-insensitive, `http`/`https` only).
3. Each matching rule adds its parameters only if the key is absent, in catalog order (never replaces).
4. Change → host answers `.cancel` and loads the rewritten URL; otherwise `.allow`.

Idempotency (add-if-absent) makes the reload's re-entry into `decidePolicyFor` a no-op — no loop.

## Layers

- **Domain** — `UrlRewriteRule` (host regex + ordered params; invalid pattern throws at construction), `RewriteUrlUseCase` (all decision logic).
- **Data** — none (static catalog); a future dynamic catalog lands here, the DI factory is the only call site that changes.
- **Presentation** — none (headless feature).
- **DI** — `UrlInterceptionFeature`: entry point; owns the catalog; `try!` = a bad pattern is a programmer error that dies in local tests, never in production.

## Usage

```swift
let feature = UrlInterceptionFeature()                     // wiring, once (main actor)

func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard action.navigationType == .linkActivated || action.navigationType == .other
    else { return decisionHandler(.allow) }
    guard let url = action.request.url,
          let rewritten = feature.rewriteUrl.rewrite(url: url)
    else { return decisionHandler(.allow) }                // no rule applies → never block
    decisionHandler(.cancel)                               // WKWebView can't edit a URL in place
    webView.load(URLRequest(url: rewritten))
}
```

## Contract (host-owned)

- `.allow` is the default for everything not claimed (other navigation types, non-http(s) URLs, unparseable inputs).
- The catalog is pinned by tests: construction validates every pattern, one behavioral pin per shipped rule.
- Whole-host match: no `^`/`$` needed; subdomain matching is an explicit pattern choice.

## Accepted limitations

- Rewriting re-encodes the existing query via `URLComponents` (semantically identical, not byte-identical).
- A parameter already present is never touched, whatever its value.
