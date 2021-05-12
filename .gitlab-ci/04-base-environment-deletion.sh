#!/bin/bash
# Script to delete environments created in pipeline

set -eo pipefail

echo "Starting 04-base-environment-deletion.sh"

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

echo "Performing PingOne environment deletion..."

#get a worker app token to run
export WORKER_APP_ACCESS_TOKEN=$(curl -s -u $ADMIN_CLIENT_ID:$ADMIN_CLIENT_SECRET \
--location --request POST "$AUTH_SERVER_BASE_URL/$ADMIN_ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "API URL path is $API_LOCATION"
echo "Worker app access token is $WORKER_APP_ACCESS_TOKEN"

export WF_ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)
echo "Workforce Environment ID is $WF_ENV_ID"

DELETE_WF_ENV=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$WF_ENV_ID" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            --data-raw '')
DELETE_WF_ENV_RESULT=$(echo $DELETE_WF_ENV | sed 's@.*}@@' )

if [[ "$DELETE_WF_ENV_RESULT" -eq "204" ]]; then
    echo "Workforce Environment successfully deleted..."
else
    echo "Workforce Environment not successfully deleted, see response below!"
    echo "$DELETE_WF_ENV"
    exit 1
fi

export CIAM_ENV_ID=$(cat "$cypress_dir"/CIAM_envid.txt)
echo "CIAM Environment ID is $CIAM_ENV_ID"

DELETE_CIAM_ENV=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$CIAM_ENV_ID" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            --data-raw '')
DELETE_CIAM_ENV_RESULT=$(echo $DELETE_CIAM_ENV | sed 's@.*}@@' )

if [[ "$DELETE_CIAM_ENV_RESULT" -eq "204" ]]; then
    echo "CIAM Environment successfully deleted..."
else
    echo "CIAM Environment not successfully deleted, see response below!"
    echo "$DELETE_CIAM_ENV"
    exit 1
fi
