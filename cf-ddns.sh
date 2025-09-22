#!/bin/sh

# Cloudflare DDNS Updater
# Required environment variables:
# - CF_ZONE_ID: The Zone ID of your domain.
# - CF_API_TOKEN: A Cloudflare API token with DNS:Edit permissions.
# - CF_RECORD_NAME: The full DNS record to update (e.g., gpt.iri1968.dpdns.org).
# - CF_TARGET_CNAME: The target CNAME value (e.g., gptproxy-xxxx.b4a.run).

# --- Validation ---
if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ] || [ -z "$CF_RECORD_NAME" ] || [ -z "$CF_TARGET_CNAME" ]; then
  echo "Error: One or more required environment variables are not set."
  exit 1
fi

# --- Get Record ID ---
echo "Fetching DNS Record ID for ${CF_RECORD_NAME}..."
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=${CF_RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "null" ]; then
  echo "Error: Could not find DNS Record ID for ${CF_RECORD_NAME}. Please ensure the CNAME record exists in Cloudflare first."
  exit 1
fi

echo "Found Record ID: ${RECORD_ID}"

# --- Update Record ---
echo "Updating DNS record to point to ${CF_TARGET_CNAME}..."
UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${CF_TARGET_CNAME}\",\"ttl\":1,\"proxied\":true}")

SUCCESS=$(echo "$UPDATE_RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
  echo "Successfully updated DNS record for ${CF_RECORD_NAME} to point to ${CF_TARGET_CNAME}."
else
  echo "Error updating DNS record:"
  echo "$UPDATE_RESPONSE"
fi
