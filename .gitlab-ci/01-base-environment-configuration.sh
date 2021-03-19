#!/bin/bash

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

#call BoM Script
echo "###### Executing BoM Script against Workforce ######"
"$sol_dir"/integration/solutions_pre-config.sh

#performing initial PingOne WF creation scripts
echo "Running WF PingFederate creation scripts."
for script in "$sol_dir"/WF/PingFederate/*set.sh; do
  echo "Executing $script..."
  bash $script 
done

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

#call BoM Script
echo "###### Executing BoM Script against CIAM ######"
"$sol_dir"/integration/solutions_pre-config.sh

#performing initial PingOne WF creation scripts
echo "Running CIAM PingFederate creation scripts."
for script in "$sol_dir"/CIAM/PingFederate/*set.sh; do
  echo "Executing $script..."
  bash $script 
done

echo "Finished 01-base-environment-configuration.sh"
