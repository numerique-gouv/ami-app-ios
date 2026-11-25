# Certificate Pinning

Pins the server certificate chains of the hosts the app talks to, on top of
the system TLS validation. The feature is a pure decision function
(`challenge + host → disposition + credential`) that the host installs in its
auth-challenge delegates; it contains no networking of its own. In the app it
is installed in two places: the web view navigation handlers (WKWebView) and
`ServerTrustUrlSession` (`Data/Network`), the URLSession used by device
registration.

Largely inspired by:
- [Apple documentation - Performing manual server trust authentication](https://developer.apple.com/documentation/foundation/performing-manual-server-trust-authentication)
- [Secure Vale blog - Deep dive into certificate pinning on iOS](https://securevale.blog/articles/deep-dive-into-certificate-pinning-on-ios/).

## Why Apple ATS pinning is not enough

ATS pinned keys (`NSPinnedLeafIdentities` / `NSPinnedCAIdentities`) are not
sufficient for this app:

- **WKWebView pinning is undocumented and unguaranteed.** ATS's baseline
  requirements (HTTPS, TLS version, cipher suites) do apply to WKWebView —
  that part is documented by Apple. But pinning via `NSPinnedDomains` is
  *not* documented for web views, and has been inconsistent in practice:
  it did not work on iOS 14–15 and appears to work on iOS 16+. The web
  view is the app's primary attack surface, and its pinning cannot rely on
  behavior Apple does not officially guarantee.
- **Sub-domain pinning is limited to first level.** When pinning `example.org`
  and setting `NSIncludesSubdomains` to `true`, `a.example.org` will be
  pinned too, but not `b.a.example.org`.
  (https://developer.apple.com/documentation/bundleresources/information-property-list/nsincludessubdomains)
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
  (`HomeViewNavigationHandler`, `ServiceViewNavigationHandler`); the URLSession
  path is provided by `ServerTrustUrlSession` (`Data/Network`), a session whose
  delegate forwards every challenge to the feature — wired in
  `DependencyContainer` for device registration, with a `nil` handler in
  environments without pinning (plain system validation).
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

## Chain validation in the trust-challenge delegate

When the app implements the server-trust auth-challenge delegate
(`WKNavigationDelegate` `respondTo challenge:` or `URLSessionDelegate`
`didReceive:`), the system consults it for the connection's server trust and
**acts on whatever disposition it returns — the delegate's decision is final.**
That is Apple's stated purpose for this hook
([Performing manual server trust authentication](https://developer.apple.com/documentation/foundation/performing-manual-server-trust-authentication)):
accept credentials the system would reject, or reject credentials the system
would accept — pinning to a set of keys under the app's control.

The consequence matters for chain validation: because `.useCredential` is
accepted **without the system re-validating**, the feature cannot lean on the
system to check the chain for us. It **re-performs the complete system
evaluation itself, before any `.useCredential`**, with the same Security APIs
and policies the system would use. The invariant:

> **A connection is never accepted on weaker validation than the system would
> have applied.**

For a pinned host, `ServerTrustEvaluator.evaluate` runs, in order:

1. **Resolve the host's pins** (the `PinRule`s whose regex matches). If no rule
   matches, the host is **not pinned**: return `false`, and `evaluate(challenge:)`
   answers `.performDefaultHandling` — the system's default validation runs.
2. **Build and apply the SSL + hostname policy** (`SecPolicyCreateSSL` with the
   challenge's host, then `SecTrustSetPolicies`).
3. **Run the full system evaluation** (`SecTrustEvaluateWithError`): chain
   building to a trusted root, hostname match, and the OS CRL/CT revocation
   (see *System checks* below). Any failure throws → fail-closed
   (`.cancelAuthenticationChallenge`).
4. **Extract the evaluated chain** (`SecTrustCopyCertificateChain`) — the
   system-resolved chain, leaf → intermediates → **root anchor**. The server
   normally sends only leaf + intermediate; the system completes the chain to
   a trusted root from the trust store. That is why a pin can match the **root**
   (or an intermediate) the server never presents.
5. **Match a pin** against *any* certificate in that validated chain: a match →
   `.useCredential`; none → `.cancelAuthenticationChallenge` (`pinningFailed`,
   carrying the presented chain for diagnosis).

Dispositions, and what happens once the delegate returns them:

| Disposition | Returned when | What happens next |
|---|---|---|
| `.useCredential` | chain fully validated **and** a pin matches | accepted **as-is**; the system does not re-validate |
| `.performDefaultHandling` | non-server-trust challenge, missing `serverTrust`, or host not pinned | the system runs its standard validation |
| `.cancelAuthenticationChallenge` | a pinned host's chain evaluation or pin match failed | the connection fails closed |

Pinning therefore **adds an identity check on top of** a full re-run of the
system's own validation — it never substitutes a weaker one.

## System checks

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
  **intermediate** and **root** pinning.

### SPKI-SHA256: the default choice

Base64 of the SHA-256 digest of the certificate's SPKI DER — the historical
HPKP `pin-sha256` format, the industry standard, and exactly what ATS
`NSPinnedLeafIdentities` and the openssl pipeline below produce. It is the
best default because **the pin is a function of the public key, not of the
certificate**:

- the certificate can be re-issued (new validity, changed SANs, new serial)
  without changing the pin by reusing the same key (i.e. the same CSR – 
  Certificate Signing Request – or using CertBot option `--reuse-key`);
- pinning the **leaf** certificate's SPKI (not the intermediate's) narrows 
  the scope of accepted certificates. Pinning intermediate CA's SPKI would validate every certificate signed by that intermediate CA. Some certificate 
  authorities (such as Let's Encrypt) discourage pinning their intermediate certificates.
  (https://letsencrypt.org/2024/04/12/changes-to-issuance-chains.html#risks-of-pinning-or-hard-coding-intermediates) 
- a key compromise breaks the pin immediately (fail-closed), which is the
  failure mode pinning exists to catch.

## Recommended pin set and fallback

- **At least two pins per host** (OR semantics — *any* matching pin
  accepts): the current leaf's SPKI-SHA256, plus a backup.
- **Backup candidates**: a second leaf of the same CA.
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
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: "<leaf SPKI sha256>"),
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: "<backup leaf SPKI sha256>"),
    ]),
])

// WKWebView (navigation handler):
func evaluateAuthChallenge(challenge: URLAuthenticationChallenge) async
    -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    guard let pinning else { return (.performDefaultHandling, nil) }
    return await pinning.evaluate(challenge: challenge)
}

// URLSession (device registration): the feature conforms to the
// `ServerTrustHandler` port (Core/Domain/Network); `ServerTrustUrlSession`
// installs it as its challenge delegate. `nil` handler = system default.
let session = ServerTrustUrlSession(handler: certificatePinningFeature,
                                    configuration: .default)
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
# intermediates (the root is usually not sent) — and the leaf
# (1st certificate) is selected and piped straight into the pin
# computation. Nothing is written locally.

# SPKI of the leaf, base64 of DER (PinFactory.spki + .sha256):
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{n++} n==1{print} /-----END CERTIFICATE-----/ && n==1{exit}' \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform DER \
  | openssl enc -base64 -A; echo

# Same, then SHA-256 digest — the classic pin (base64 of the digest):
openssl s_client -connect example.com:443 -servername example.com -showcerts </dev/null 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{n++} n==1{print} /-----END CERTIFICATE-----/ && n==1{exit}' \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64 -A; echo
```

`-servername` sends the SNI (the presented chain depends on it); `n==1`
selects the leaf — use `n==2` for the intermediate; `-A` keeps the
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
`PinRule` and the pin nodes. Outward, the feature plays the
`ServerTrustHandler` port (`Core/Domain/Network`) — the contract spoken by
both the web view navigation handlers and the transport
(`Data/Network/ServerTrustUrlSession`); `Composition/` wires them.
