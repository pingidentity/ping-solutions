#!/bin/bash
# Script to verify features and types

echo "Performing PingOne configuration revertion"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATIONS"
echo "Current pipeline version is $CURRENT_PIPELINE_VERSION"
echo "Current Org ID is $ORG_ID"

export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Worker token is $WORKER_APP_ACCESS_TOKEN"

#performing final PingOne revertion/deletion scripts
for script in ./Solutions/WF/$CURRENT_PIPELINE_VERSION/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done

