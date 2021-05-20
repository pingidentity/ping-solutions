#!/bin/bash
# Script to configure PingOne instance to trial specifications
#wes is a punk

set -eo pipefail

#gimme jq
JQ=/usr/bin/jq
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > $JQ && chmod +x $JQ
ls -la $JQ

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")

#cleanup in case of failure
find "$cypress_dir"/integration/ -name *.js -type f -delete
find "$script_dir" -name *.txt -type f -delete


#Let's set up some variables in case someone new is running this. Much of this is done by pipeline or other resources
if [ -z ${API_LOCATION+x} ]; then 
    #not set, let's do it!
  export API_LOCATION='https://api.pingone.com/v1' 
fi
if [ -z ${DOMAIN+x} ]; then 
    #not set, let's do it!
  export DOMAIN='example.com' 
fi
if [ -z ${PINGFED_BASE_URL+x} ]; then 
    #not set, let's do it!
  export PINGFED_BASE_URL='https://localhost' 
fi
if [ -z ${CYPRESS_PROJECT_ID+x} ]; then 
    #not set, let's do it!
  export CYPRESS_PROJECT_ID='null'
fi

if [ -z ${ADMIN_ENV_ID+x} ]; then echo "ENV ID is unset" && exit 1; else echo "Admin Environment ID is $ADMIN_ENV_ID"; fi
if [ -z ${CONSOLE_USERNAME+x} ]; then echo "Console username is unset" && exit 1; else echo "Console user is $CONSOLE_USERNAME"; fi
if [ -z ${CONSOLE_PASSWORD+x} ]; then echo "Console password is unset" && exit 1; else echo "Console password is set."; fi

if [[ $CYPRESS_PROJECT_ID -ne 'null' ]]; then
  echo "Cypress project ID is $CYPRESS_PROJECT_ID. Cypress key is $CYPRESS_RECORD_KEY"
fi

cat "$script_dir"/cypress.d/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$cypress_dir"/../cypress.json

#!/bin/bash

set -eo pipefail

echo "Starting 00-CIAM-variable-set.sh"

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $API_CLIENT_ID:$API_CLIENT_SECRET \
--location --request POST "$AUTH_SERVER_BASE_URL/as/token.oauth2" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

#echo Variables to verify
echo "API_LOCATION=$API_LOCATION"
echo "ENV_ID=$ENV_ID"
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN"
echo "PINGFED_BASE_URL=$CIAM_PINGFED_BASE_URL"
echo "PF_USERNAME=$PF_USERNAME"
echo "PF_PASSWORD=$PF_PASSWORD"
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL"
echo "PLAYBOOK=pf_post_playbook.yml -vvv"
