APNs test scripts

This folder contains a helper script to send APNs pushes directly to Apple using token-based (p8) authentication.

Script
- `apns_location_push.sh`: sends a Location Push (`push_type=location`) or Background push to sandbox or production.

Requirements
- macOS with `curl` and `openssl` available in PATH.
- An APNs Auth Key (`AuthKey_<KEY_ID>.p8`), your Apple Developer `TEAM_ID`, and `KEY_ID`.
- The device token printed by your app at registration time.

Usage

1) Make the script executable:
   chmod +x scripts/apns/apns_location_push.sh

2) Send Location Push (sandbox):
   scripts/apns/apns_location_push.sh \
     --team-id YOUR_TEAM_ID \
     --key-id YOUR_KEY_ID \
     --p8 /path/to/AuthKey_YOUR_KEY_ID.p8 \
     --bundle-id com.prey \
     --device-token YOUR_DEVICE_TOKEN \
     --env sandbox \
     --push-type location \
     --priority high

3) Send Background push (sandbox):
   scripts/apns/apns_location_push.sh \
     --team-id YOUR_TEAM_ID \
     --key-id YOUR_KEY_ID \
     --p8 /path/to/AuthKey_YOUR_KEY_ID.p8 \
     --bundle-id com.prey \
     --device-token YOUR_DEVICE_TOKEN \
     --env sandbox \
     --push-type background \
     --priority normal

Notes
- For production, use `--env prod` and a distribution token (AdHoc/TestFlight/AppStore).
- For Location Push, the script sets `apns-topic` to `<BUNDLE_ID>.location-query`, `apns-priority=10` when `--priority high`.
- For Background, the script sets `apns-topic` to `<BUNDLE_ID>` and sends a minimal `{"aps":{"content-available":1}}` payload when no custom payload is provided.

