#!/bin/bash

#set the base dir location
script_dir="$(cd "$(dirname "$0")";cd ../../; pwd)"
#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")

  #variables needed
  #API_LOCATION
  #WORKER_APP_ACCESS_TOKEN
  #RUNNER_USER_TEST_PASSWORD
  #ENV_ID
  #RINGCENTRAL_SECRET
  #RINGCENTRAL_USERNAME
  #RINGCENTRAL_PASSWORD

  #This script gets a user, using user number 1 from array of users to avoid relying on a specific sample user (hopefully there's always at least 2 users). 
  #the script will then get a RingCentral token, populate information in the Cypress javascript file, then place it into 03_CIAM_TESTS to be picked up by the Cypress docker test run.
  
#get our user 
USER_ACCT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq '._embedded.users[2]')

USER_ACCT_ID=$(echo $USER_ACCT | jq -rc '.id')

USER_NAME=$(echo $USER_ACCT | jq -rc '.username')
echo "username is $USER_NAME"

#update the password
USER_PASS_SET=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/users/$USER_ACCT_ID/password" \
--header 'Content-Type: application/vnd.pingidentity.password.set+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  \
--data-raw '{
  "value": "'"$RUNNER_USER_TEST_PASSWORD"'",
  "forceChange": false
}')


USER_MFA_SET=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/users/$USER_ACCT_ID/mfaEnabled" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "mfaEnabled": true
}')

#Set RINGCENTRAL phone number as the MFA option for Antonik
SMS_ADD=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users/$USER_ACCT_ID/devices" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "type": "SMS",
    "phone": "'"$RINGCENTRAL_USERNAME"'"
}')

#get RingCentral token to use in script
export RO_TOKEN=$(curl -s -X POST "https://platform.devtest.ringcentral.com/restapi/oauth/token" \
--header "Accept: application/json" \
--header "Content-Type: application/x-www-form-urlencoded" \
-u "$RINGCENTRAL_SECRET" \
-d "username=$RINGCENTRAL_USERNAME&password=$RINGCENTRAL_PASSWORD&extension=101&grant_type=password" \
| jq -rc .access_token)

sms_script=$(echo "$script_dir/cypress.d/base_files/supp_tests/CIAM/sms_login.js")
new_sms_script=$(echo ".gitlab-ci/cypress.d/cypress/integration/03_CIAM_TESTS/900_sms_login.js")
cat $sms_script | \
sed -e "s/ENV_ID/$ENV_ID/g" -e "s/TEST_USERNAME/$USER_NAME/g" -e "s/RO_TOKEN/$RO_TOKEN/g" >> \
$cypress_dir/integration/CIAM/set.js
