#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 \\
  --team-id TEAM_ID \\
  --key-id KEY_ID \\
  --p8 /path/to/AuthKey_KEYID.p8 \\
  --bundle-id com.example.app \\
  --device-token DEVICE_TOKEN \\
  --env sandbox|prod \\
  [--push-type location|background] \\
  [--priority high|normal] \\
  [--payload JSON]

Defaults:
  --push-type location
  --priority  high  (maps to apns-priority=10; normal=5)
  --payload  '{}' for location; '{"aps":{"content-available":1}}' for background
USAGE
}

TEAM_ID=""
KEY_ID=""
P8_KEY_PATH=""
BUNDLE_ID=""
DEVICE_TOKEN=""
ENVIRONMENT=""
PUSH_TYPE="location"
PRIORITY="high"
PAYLOAD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team-id) TEAM_ID="$2"; shift 2;;
    --key-id) KEY_ID="$2"; shift 2;;
    --p8) P8_KEY_PATH="$2"; shift 2;;
    --bundle-id) BUNDLE_ID="$2"; shift 2;;
    --device-token) DEVICE_TOKEN="$2"; shift 2;;
    --env) ENVIRONMENT="$2"; shift 2;;
    --push-type) PUSH_TYPE="$2"; shift 2;;
    --priority) PRIORITY="$2"; shift 2;;
    --payload) PAYLOAD="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -z "$TEAM_ID" || -z "$KEY_ID" || -z "$P8_KEY_PATH" || -z "$BUNDLE_ID" || -z "$DEVICE_TOKEN" || -z "$ENVIRONMENT" ]] && { usage; exit 1; }

command -v openssl >/dev/null 2>&1 || { echo "openssl not found"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl not found"; exit 1; }

if [[ ! -f "$P8_KEY_PATH" ]]; then
  echo "p8 key not found at: $P8_KEY_PATH"; exit 1;
fi

# Compute APNs HTTP/2 host
case "$ENVIRONMENT" in
  sandbox) APNS_HOST="https://api.sandbox.push.apple.com";;
  prod|production) APNS_HOST="https://api.push.apple.com";;
  *) echo "Invalid --env: $ENVIRONMENT (use sandbox|prod)"; exit 1;;
esac

# Map push-type to topic and default payload
case "$PUSH_TYPE" in
  location)
    TOPIC="${BUNDLE_ID}.location-query"
    [[ -z "$PAYLOAD" ]] && PAYLOAD='{}'
    ;;
  background)
    TOPIC="$BUNDLE_ID"
    [[ -z "$PAYLOAD" ]] && PAYLOAD='{"aps":{"content-available":1}}'
    ;;
  *) echo "Invalid --push-type: $PUSH_TYPE (use location|background)"; exit 1;;
esac

# Map priority to APNs numeric
case "$PRIORITY" in
  high) APNS_PRIORITY=10;;
  normal) APNS_PRIORITY=5;;
  *) echo "Invalid --priority: $PRIORITY (use high|normal)"; exit 1;;
esac

# Build JWT for APNs (ES256)
b64url() { openssl base64 -e -A | tr '+/' '-_' | tr -d '='; }
HEADER='{"alg":"ES256","kid":"'"$KEY_ID"'"}'
CLAIMS='{"iss":"'"$TEAM_ID"'","iat":'$(date +%s)'}'
JWT_HEADER=$(printf %s "$HEADER" | b64url)
JWT_CLAIMS=$(printf %s "$CLAIMS" | b64url)
SIGNING_INPUT="${JWT_HEADER}.${JWT_CLAIMS}"
SIGNATURE=$(printf %s "$SIGNING_INPUT" | openssl dgst -sha256 -sign "$P8_KEY_PATH" -binary | b64url)
JWT="${SIGNING_INPUT}.${SIGNATURE}"

set -x
curl -v --http2 \
  -H "apns-topic: ${TOPIC}" \
  -H "apns-push-type: ${PUSH_TYPE}" \
  -H "apns-priority: ${APNS_PRIORITY}" \
  -H "authorization: bearer ${JWT}" \
  -d "$PAYLOAD" \
  "${APNS_HOST}/3/device/${DEVICE_TOKEN}"
set +x

