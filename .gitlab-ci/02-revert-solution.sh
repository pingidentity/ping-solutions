#!/bin/bash
# Script to revert features and types

echo "Performing PingOne configuration revertion"

#WORKFORCEEEEEEEEEEE

#set Ping One variables for WF
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/envid.txt)

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne WF configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "Current Org ID is $ORG_ID"
echo "WF worker token is $WORKER_APP_ACCESS_TOKEN"


#performing final PingOne revertion/deletion scripts
echo "Running WF revert scripts . . . ..  .. . ."
for script in ./Solutions/WF/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done

#CCCCCCCCIIIIIIIIIAAAAAAAAAMMMMMMMMM

#set Ping One variables for CIAM
export CLIENT_ID=$CIAM_CLIENT_ID
export CLIENT_SECRET=$CIAM_CLIENT_SECRET
export ENV_ID=$CIAM_ENV_ID

#get a worker app token to run our tests (CIAM)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne CIAM configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "Current Org ID is $ORG_ID"
echo "CIAM worker token is $WORKER_APP_ACCESS_TOKEN"

#performing final PingOne CIAM revert scripts
echo "Running CIAM revert scripts . . . . . . . . . ."
#performing final PingOne revertion/deletion scripts
for script in ./Solutions/CIAM/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done