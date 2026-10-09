# PromotedUrls Feature

Intercepts web view navigations to known destinations (identified by a URL
suffix) and, when the app's local policy says so, opens a native screen
instead of letting the page navigate.

## How it works

1. The web page owns the **catalog**: pairs of `alias` + URL suffix `pattern`; the host pulls it via a closure (`CatalogProvider`) once the page is fully loaded — no JS injection, no message handlers.
2. The repository combines the page catalog with local `PromotedAliases`
   (alias → `AppRoute`), dropping unknown aliases and invalid patterns
   (empty / not starting with `/`). Eligible aliases get
   `.native(route)`; the rest `.webPage`.
3. On a link tap, the URL is resolved by **suffix match**
   (`absoluteString.hasSuffix(pattern)`): the pattern must be the tail of
   the navigation URL, so trailing query parameters prevent a match
   (accepted limitation). `.native` destinations are intercepted
   (`.cancel` + open route); everything else passes through.

## Layers

`Domain/` entities, repository protocol, use cases — `Data/` DTO, closure data source, caching repository, error, module — `Presentation/` view model — `DI/PromotedUrlsFeature` (single entry point).

## Usage

```swift
let feature = PromotedUrlsFeature(catalogProvider: { /* read catalog from the ready page */ })

// existing "page fully loaded" event:
Task { await feature.viewModel.prepare() }

// WKNavigationDelegate:
guard action.navigationType == .linkActivated,
      let url = action.request.url,
      let route = try? await feature.handleNavigationUseCase.handle(url: url)
else { return .allow }
open(route)      // app routing
return .cancel
```

## Contract

- Only **link-activated** navigations are intercepted; redirects and
  programmatic navigations always pass through.
- Any failure (page not ready, invalid payload, not loaded yet) means
  **do not intercept** — the feature degrades, it never breaks the page.
- Page readiness is the **host's** responsibility: the provider closure is
  only called once the page is ready.
- Eligibility is local policy: `PromotedAliases.route` (`nil` = known but
  not eligible yet).
