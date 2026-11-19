# Certificate Pinning

Pins the server certificate chains of the hosts the app talks to, on top of
the system TLS validation. The feature is a pure decision function
(`challenge + host → disposition + credential`) that the host installs in its
auth-challenge delegates; it contains no networking of its own.

Largely inspired by
[Deep dive into certificate pinning on iOS](https://securevale.blog/articles/deep-dive-into-certificate-pinning-on-ios/).

## Why Apple ATS pinning is not enough

ATS pinned keys (`NSPinnedLeafKeys` / `NSPinnedIntermediateKeys`) are not
sufficient for this app:

- **WKWebView pinning is undocumented and unguaranteed.** ATS's baseline
  requirements (HTTPS, TLS version, cipher suites) do apply to WKWebView —
  that part is documented by Apple. But pinning via `NSPinnedDomains` is
  *not* documented for web views, and has been inconsistent in practice:
  it did not work on iOS 14–15 and appears to work on iOS 16+. The web
  view is the app's primary attack surface, and its pinning cannot rely on
  behavior Apple does not officially guarantee.
- **No observability.** A pin failure surfaces as a generic
  `NSURLErrorServerCertificateUntrusted` (-1200): no way to know which pin
  failed, which chain was presented, or to log/diagnose the decision.
- **Coarse host policy.** Exact domain + `NSIncludesSubdomains` boolean —
  no expressive host patterns.
- **No decision hook.** The pin check is a black box inside the system: no
  per-challenge callback, no integration point for logging or fallback
  policy.

## What the programmatic implementation buys

- **Covers both WKWebView and URLSession.** The feature is delegate-agnostic:
  `evaluate(challenge:)` speaks the
  `URLAuthenticationChallenge → (disposition, credential)` contract used by
  both `WKNavigationDelegate` and `URLSessionDelegate` callbacks. The web
  view path is wired through the navigation handlers
  (`HomeViewNavigationHandler`, `ServiceViewNavigationHandler`); the same
  `evaluate()` can be installed in any `URLSession` delegate.
- **Pinning layers on system validation, never replaces it.** Full chain +
  hostname validation runs first; a broken chain fails even if a pin would
  match.
- **Fail-closed where it matters, graceful elsewhere.** Pinned host with an
  evaluation error → challenge cancelled. Host with no pin rule → system
  default handling.
- **Observable.** Every decision can be logged; `pinningFailed` carries the
  presented chain (key descriptions) for diagnosis.
- **Expressive.** Regex host matching, several pin types and digests,
  several pins per host.
- **Testable.** Evaluation is a pure function; the unit-test suite lives in
  `targets/unitTests/Sources/Features/CertificatePinning/`.

## System checks (done by iOS before pinning)

`SecTrustEvaluateWithError` applies the system trust policy. Per Apple's
[Security guide](https://support.apple.com/fr-fr/guide/security/sec100a75d12/web):

> On devices with iOS 11 or later and macOS 10.13 or later, Apple devices
> are periodically updated with a current list of revoked and constrained
> certificates.

> On devices with iOS 12.1, certificates issued after October 15, 2018, from
> a system-trusted root certificate need to be logged in a trusted
> Certificate Transparency log to be allowed for TLS connections.

So revocation (CRL/OCSP data maintained by the OS) and Certificate
Transparency are already enforced before a pin is consulted — the feature
adds identity binding, not another online check. A stricter *live* OCSP
opt-in (`SecPolicyCreateRevocation`) is documented in
`ServerTrustEvaluator.swift` should it ever be mandated.

## Pinning mechanisms

Pins are built with `PinFactory` × `PinHashingAlgorithmType`:

| Factory            | Node          | Identifying material stored            |
|--------------------|---------------|----------------------------------------|
| `.certificate`     | `Certificate` | the full X.509 certificate (DER)       |
| `.publicKey(.p256 / .p384 / .p521 / .rsa)` | `PublicKey` | the raw key (X9.63 point / PKCS#1) |
| `.spki`            | `SPKI`        | the SubjectPublicKeyInfo TLV           |

- `algorithm: nil` stores the **raw** material (exact byte-for-byte match —
  collision-free, but long); `.sha256` / `.sha384` / `.sha512` — and
  `.sha3_256` / `.sha3_384` / `.sha3_512`, only available on iOS 26+ —
  store the digest (`HashedPin`), the compact classic form.
- **Chain position is free**: a pin is matched against *any* certificate of
  the validated chain, so the same mechanism covers **leaf**,
  **intermediate** and **root** pinning. Caveats: a root pin only matches if
  the server actually presents the root in the chain (many don't), and it
  binds everything the CA ever issues.

### SPKI-SHA256: the default choice

Base64 of the SHA-256 digest of the certificate's SPKI DER — the historical
HPKP `pin-sha256` format, the industry standard, and exactly what ATS
`NSPinnedIntermediateKeys` and the openssl pipeline below produce. It is the
best default because **the pin is a function of the public key, not of the
certificate**:

- the certificate can be re-issued (new validity, changed SANs, new serial)
  without changing the pin;
- pinning the **intermediate** CA's SPKI (not the leaf) survives automatic
  leaf rotation (90-day certificates, issuer changes) as long as the
  issuing key is unchanged;
- a key compromise breaks the pin immediately (fail-closed), which is the
  failure mode pinning exists to catch.

## Recommended pin set and fallback

- **At least two pins per host** (OR semantics — *any* matching pin
  accepts): the current intermediate's SPKI-SHA256, plus a backup.
- **Backup candidates**: a sibling intermediate of the same CA (e.g. the
  other intermediates of the issuing CA, for CAs that rotate them), or the
  issuer root's SPKI-SHA256 *if the server presents the root*.
- **Rotation is a two-step app update**: ship the new pin *alongside* the
  old one (OR semantics → zero downtime), then drop the old one once the
  infrastructure has fully moved. **Never ship a host with a single pin.**
- **Unpinned hosts are the outer fallback layer**: no matching rule means
  system validation only — pinning degrades, it never blocks hosts it does
  not claim.

## Usage

```swift
let pinning = CertificatePinningFeature(pinRules: [
    PinRule(pattern: "^www\\.cloudflare\\.com$", pins: [
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: "<intermediate SPKI sha256>"),
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: "<backup SPKI sha256>"),
    ]),
])

// WKWebView (navigation handler):
func evaluateAuthChallenge(challenge: URLAuthenticationChallenge) async
    -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    guard let pinning else { return (.performDefaultHandling, nil) }
    return await pinning.evaluate(challenge: challenge)
}

// URLSession: install the same evaluate() in the session delegate's
// `urlSession(_:didReceive:completionHandler:)`.
```

`PinRule` and `ServerTrustEvaluator` fail fast at build time
(`preconditionFailure`) on an uncompilable pattern or a pin that failed to
build: an app with a broken pin set must not start.

## Pin extraction (openssl)

The repository ships `scripts/ami-certificate-pinning-info.sh HOST
leaf|intermediate|INDEX [PORT]`, which fetches the chain and prints the
selected certificate's pins; the pipelines below are the manual equivalent.

```bash
# The chain is fetched live from the host — leaf first, then
# intermediates (the root is usually not sent) — and the intermediate
# (2nd certificate) is selected and piped straight into the pin
# computation. Nothing is written locally.

# SPKI of the intermediate, base64 of DER (PinFactory.spki + .sha256):
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{n++} n==2{print} /-----END CERTIFICATE-----/ && n==2{exit}' \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform DER \
  | openssl enc -base64 -A; echo

# Same, then SHA-256 digest — the classic pin (base64 of the digest):
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{n++} n==2{print} /-----END CERTIFICATE-----/ && n==2{exit}' \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64 -A; echo
```

`-servername` sends the SNI (the presented chain depends on it); `n==2`
selects the first intermediate — use `n==1` for the leaf; `-A` keeps the
output on one line (wrapped base64 is rejected by `Data(base64Encoded:)`).

## Layers

```
Model/          TrustChainNode, ServerTrustEvaluating, PinRule, SendableRegex
Data/Model/     Certificate, PublicKey, SPKI, HashedPin, PinFactory,
                RSASigningPublicKey, DERRepresentable, SendableTrustChainNode
Data/DataSources/ ServerTrustEvaluator   (validate-first + pin matching)
Data/Errors/    CertificatePinningError
DI/             CertificatePinningFeature   (host-facing entry point)
```

Dependencies point inward: Presentation holds the feature (optional, nil =
pass-through); the feature owns the evaluator; the evaluator consumes
`PinRule` and the pin nodes.
