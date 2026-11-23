#!/usr/bin/env bash
# Usage: cert-info.sh HOST leaf|intermediate|INDEX [PORT]
#   leaf         = 1st certificate sent by the server
#   intermediate = 2nd certificate sent by the server
#   INDEX        = position (1-based) in the chain as sent by the server
# Extracts the selected certificate and prints:
#   certificate, public key and SPKI in Base64 (64-char lines), and their SHA-256 digests in Base64
set -euo pipefail
usage() { echo "Usage: $0 HOST leaf|intermediate|INDEX [PORT]   (INDEX: 1 = leaf, 2 = intermediate, ...)" >&2; exit 64; }
HOST=${1:-}; LEVEL=${2:-}; PORT=${3:-443}
[ -n "$HOST" ] || usage
case "$LEVEL" in
  leaf)            INDEX=1;;
  intermediate)    INDEX=2;;
  [1-9]|[1-9][0-9]) INDEX=$LEVEL;;
  *)               usage;;
esac
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

b64()    { openssl base64 -in "$1"; }                               # wrapped at 64 chars
sha256() { openssl dgst -sha256 -binary "$1" | openssl base64 -A; } # single line

# 1. Fetch the chain once, then keep the requested certificate
openssl s_client -connect "$HOST:$PORT" -servername "$HOST" -showcerts </dev/null 2>/dev/null \
  > "$TMP/chain.txt" || true
COUNT=$(grep -c 'BEGIN CERTIFICATE' "$TMP/chain.txt" || true)
[ "$COUNT" -gt 0 ] || { echo "Error: no certificate received from $HOST:$PORT" >&2; exit 1; }
[ "$INDEX" -le "$COUNT" ] || {
  echo "Error: $HOST sent $COUNT certificate(s); there is no certificate #$INDEX" >&2; exit 1; }
awk -v i="$INDEX" '/BEGIN CERT/{n++} n==i' "$TMP/chain.txt" | openssl x509 -out "$TMP/cert.pem"

# Role of the selected certificate
SUBJ=$(openssl x509 -in "$TMP/cert.pem" -noout -subject | sed 's/^subject= *//')
ISSU=$(openssl x509 -in "$TMP/cert.pem" -noout -issuer  | sed 's/^issuer= *//')
if   [ "$INDEX" -eq 1 ];      then ROLE="leaf"
elif [ "$SUBJ" = "$ISSU" ];   then ROLE="self-signed root"
else                               ROLE="CA certificate (intermediate or cross-signed root)"
fi

# 2. Certificate (DER)
openssl x509 -in "$TMP/cert.pem" -outform DER -out "$TMP/cert.der"

# 3. SPKI (DER): AlgorithmIdentifier + BIT STRING { public key }
openssl x509 -in "$TMP/cert.pem" -noout -pubkey | openssl pkey -pubin -outform DER -out "$TMP/spki.der"

# 4. Public key = contents of the SPKI BIT STRING (its last element), minus the unused-bits byte
#    (= SecKeyCopyExternalRepresentation on Apple platforms)
LEN=$(openssl asn1parse -inform DER -in "$TMP/spki.der" \
      | awk '/BIT STRING/{l=$0} END{sub(/.*l= */,"",l); sub(/ .*/,"",l); print l}')
tail -c $((LEN - 1)) "$TMP/spki.der" > "$TMP/pubkey.bin"

# 5. Public key type
TEXT=$(openssl x509 -in "$TMP/cert.pem" -noout -text)
ALG=$(awk -F': ' '/Public Key Algorithm/{print $2; exit}' <<<"$TEXT")
BITS=$(sed -n 's/.*Public-Key: (\([0-9]*\) bit).*/\1/p' <<<"$TEXT" | head -1)
OID=$(awk -F': ' '/ASN1 OID/{print $2; exit}' <<<"$TEXT")
NIST=$(awk -F': ' '/NIST CURVE/{print $2; exit}' <<<"$TEXT")
case "$ALG" in
  rsaEncryption)  KEYTYPE="RSA $BITS bits";              KEYFMT="PKCS#1 RSAPublicKey (DER)";;
  id-ecPublicKey) KEYTYPE="EC ${NIST:-$OID} ($OID), $BITS bits"; KEYFMT="X9.63 uncompressed point (04 || X || Y)";;
  ED25519|ED448)  KEYTYPE="$ALG";                        KEYFMT="raw ${ALG} public key";;
  *)              KEYTYPE="$ALG${BITS:+, $BITS bits}";   KEYFMT="contents of the SPKI BIT STRING";;
esac

echo "Host:    $HOST:$PORT"
echo "Level:   $LEVEL"
echo "Subject: $(openssl x509 -in "$TMP/cert.pem" -noout -subject | sed 's/^subject= *//')"
echo "Issuer:  $(openssl x509 -in "$TMP/cert.pem" -noout -issuer  | sed 's/^issuer= *//')"
echo
echo "Certificate ($(wc -c < "$TMP/cert.der") bytes, DER):"
b64 "$TMP/cert.der"
echo
echo "Certificate SHA-256: $(sha256 "$TMP/cert.der")"
echo
echo "Public key: $KEYTYPE ($(wc -c < "$TMP/pubkey.bin") bytes, $KEYFMT):"
b64 "$TMP/pubkey.bin"
echo
echo "Public key SHA-256:  $(sha256 "$TMP/pubkey.bin")"
echo
echo "SPKI ($(wc -c < "$TMP/spki.der") bytes, DER):"
b64 "$TMP/spki.der"
echo
echo "SPKI SHA-256:        $(sha256 "$TMP/spki.der")   <- SPKI-SHA256-BASE64 pin"