#!/bin/bash

set -eo pipefail

echo "Executing 01-base-environment-configuration.sh"

#gimme jq
JQ=/usr/bin/jq
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > $JQ && chmod +x $JQ
ls -la $JQ

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the solution directory
sol_dir="$(cd "$(dirname "$0")";cd ../Solutions; pwd)"

#cleanup
cypress_dir=$(echo "$script_dir/../cypress")
find "$cypress_dir/integration/" -name *.js -type f -delete

#set Ping One variables for WF
export CLIENT_ID=$(cat "$cypress_dir"/WF_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/WF_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne WF configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "WF worker token is $WORKER_APP_ACCESS_TOKEN"

#finessse the BoM
PFeddy_add=$(curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/billOfMaterials" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
--data-raw '{
  "products": [
    {
      "type": "PING_FEDERATE"
    },
    {
        "type": "PING_ONE_VERIFY"
    },
    {
        "type": "PING_ONE_BASE"
    },
    {
        "type": "PING_ID"
    },
    {
        "type": "PING_ONE_RISK"
    }
  ]
}')

#call BoM Script
echo "###### Executing BoM Script against Workforce ######"
"$sol_dir"/integrations/solutions_pre-config.sh
"$sol_dir"/integrations/solutions_pf_pre-config.sh
"$sol_dir"/integrations/solutions_p1_pf_pre-config.sh

#CCCCCCCCIIIIIIIIIAAAAAAAAAMMMMMMMMM

#set Ping One variables for CIAM
export CLIENT_ID=$(cat "$cypress_dir"/CIAM_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/CIAM_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/CIAM_envid.txt)

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne CIAM configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "CIAM worker token is $WORKER_APP_ACCESS_TOKEN"

#finessse the BoM
PFeddy_add=$(curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/billOfMaterials" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
--data-raw '{
  "products": [
    {
      "type": "PING_FEDERATE"
    },
    {
        "type": "PING_ONE_VERIFY"
    },
    {
        "type": "PING_ONE_BASE"
    },
    {
        "type": "PING_ONE_MFA"
    },
    {
        "type": "PING_ONE_RISK"
    }
  ]
}')

#call BoM Script
echo "###### Executing BoM Script against CIAM ######"
"$sol_dir"/integrations/solutions_pre-config.sh
"$sol_dir"/integrations/solutions_pf_pre-config.sh
"$sol_dir"/integrations/solutions_p1_pf_pre-config.sh

echo "Finished 01-base-environment-configuration.sh"