#!/bin/bash
# Script to test PingOne instance against trial specifications

set -eo pipefail

echo "Executing 02-cypress-substitution.sh"

#gimme jq
JQ=/usr/bin/jq
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > $JQ && chmod +x $JQ
ls -la $JQ

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"

cypress_dir=$(echo "$script_dir/../cypress")

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



#setup the env name
export WF_ENV_NAME=$(cat "$cypress_dir"/WF_ENV_NAME.txt)
export CIAM_ENV_NAME=$(cat "$cypress_dir"/CIAM_ENV_NAME.txt)

#set Ping One variables for WF
export CLIENT_ID=$(cat "$cypress_dir"/WF_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/WF_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -s -u $ADMIN_CLIENT_ID:$ADMIN_CLIENT_SECRET \
--location --request POST "$AUTH_SERVER_BASE_URL/$ADMIN_ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')



echo "Performing WF variable substitution..."
#create generation
cat "$script_dir"/cypress.d/base_files/base_set.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" >> \
"$cypress_dir"/integration/WF/set.js

#concatenate the configured WF test suite
for script in "$script_dir"/cypress.d/base_files/WF/*set.js; do
    echo "Copying $script..."
    cat $script | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" >> \
    $cypress_dir/integration/WF/set.js
done

#close the cypress test script
echo "
})" >> $cypress_dir/integration/WF/set.js

#revert generation
cat "$script_dir"/cypress.d/base_files/base_revert.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" >> \
"$cypress_dir"/integration/WF/revert.js

#concatenate the revert WF test suite
for script in "$script_dir"/cypress.d/base_files/WF/*revert.js; do
    echo "Copying $script..."
    cat $script | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" >> \
    $cypress_dir/integration/WF/revert.js
done

#close the cypress test script
echo "
})" >> $cypress_dir/integration/WF/revert.js

#delete generation
cat "$script_dir"/cypress.d/base_files/env_files/delete_env.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/PROD_NM/WF/g" > \
"$cypress_dir"/integration/WF/01-delete_WF_env.js


#set Ping One variables for CIAM
export CLIENT_ID=$(cat "$cypress_dir"/CIAM_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/CIAM_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/CIAM_envid.txt)

#get a worker app token to run our tests (CIAM)
export WORKER_APP_ACCESS_TOKEN=$(curl -s -u $ADMIN_CLIENT_ID:$ADMIN_CLIENT_SECRET \
--location --request POST "$AUTH_SERVER_BASE_URL/$ADMIN_ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

#echo "Performing tests on configured state."
echo "Performing CIAM variable substitution..."

#create generation
cat "$script_dir"/cypress.d/base_files/base_set.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" >> \
"$cypress_dir"/integration/CIAM/set.js

#concatenate the configured CIAM test suite
for script in "$script_dir"/cypress.d/base_files/CIAM/*set.js; do
    echo "Copying $script..."
    cat $script | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" >> \
    $cypress_dir/integration/CIAM/set.js
done

#add the supplemental tests for CIAM into the script generation
#including supplemental test scripts
echo "Adding additional CIAM test config scripts"
for script in "$script_dir"/test_scripts/CIAM/*.sh; do
    echo "Executing $script..."
    bash $script
done

#close the cypress test script
echo "
})" >> $cypress_dir/integration/CIAM/set.js

#revert generation
cat "$script_dir"/cypress.d/base_files/base_revert.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" >> \
"$cypress_dir"/integration/CIAM/revert.js

#concatenate the revert CIAM test suite
for script in "$script_dir"/cypress.d/base_files/CIAM/*revert.js; do
    echo "Copying $script..."
    cat $script | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" >> \
    $cypress_dir/integration/CIAM/revert.js
done

#close the cypress test script
echo "
})" >> $cypress_dir/integration/CIAM/revert.js

#delete generation
cat "$script_dir"/cypress.d/base_files/env_files/delete_env.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" -e "s/PROD_NM/CIAM/g" > \
"$cypress_dir"/integration/CIAM/02-delete_CIAM_env.js

cat "$script_dir"/cypress.d/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$cypress_dir"/cypress.json

echo "Finished 02-cypress-substitution.sh"
