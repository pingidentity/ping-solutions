#!/bin/bash
# Script to revert features and types

echo "Starting 03-base-environment-revert.sh"

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the solution directory
sol_dir="$(cd "$(dirname "$0")";cd ../; pwd)"

#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")

#gimme jq
JQ=/usr/bin/jq
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > $JQ && chmod +x $JQ
ls -la $JQ

#Let's set up some variables in case someone new is running this. Much of this is done by pipeline or other resources
if [ -z ${API_LOCATION+x} ]; then 
    #not set, let's do it!
  API_LOCATION='https://api.pingone.com/v1' 
fi
if [ -z ${DOMAIN+x} ]; then 
    #not set, let's do it!
  DOMAIN='example.com' 
fi
if [ -z ${PINGFED_BASE_URL+x} ]; then 
    #not set, let's do it!
  PINGFED_BASE_URL='https://localhost' 
fi
if [ -z ${CYPRESS_PROJECT_ID+x} ]; then 
    #not set, let's do it!
  CYPRESS_PROJECT_ID='null'
fi
if [ -z ${CONFIGURE_CIAM+x} ]; then 
    #not set, let's do it!
  CONFIGURE_CIAM=true
fi
if [ -z ${CONFIGURE_WF+x} ]; then 
    #not set, let's do it!
  CONFIGURE_WF=true
fi


echo "Performing PingOne configuration revertion"

#WORKFORCEEEEEEEEEEE
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
echo "Current Org ID is $ORG_ID"
echo "WF worker token is $WORKER_APP_ACCESS_TOKEN"
#performing final PingOne WF revertion/deletion scripts
echo "Running WF PingFederate revertion scripts ....       ..   .. .  ."
for script in "$sol_dir"/Solutions/WF/PingFederate/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done
#performing final PingOne revertion/deletion scripts
echo "Running WF PingOne revertion scripts . . . ..  .. . ."
for script in "$sol_dir"/Solutions/WF/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done




#CCCCCCCCIIIIIIIIIAAAAAAAAAMMMMMMMMM
#set Ping One variables for CIAM
export CLIENT_ID=$(cat "$cypress_dir"/CIAM_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/CIAM_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/CIAM_envid.txt)

#get a worker app token to run our tests (WF)
unset WORKER_APP_ACCESS_TOKEN
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
echo "Running CIAM PingFederate revert scripts . . . . . . . . . ."
#performing final PingOne WF revertion/deletion scripts
for script in "$sol_dir"/Solutions/CIAM/PingFederate/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done
#performing final PingOne revertion/deletion scripts
echo "Running CIAM PingOne revert scripts . . . . . . . . . ."
for script in "$sol_dir"/Solutions/CIAM/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done

echo "Finished 03-base-environment-revert.sh"