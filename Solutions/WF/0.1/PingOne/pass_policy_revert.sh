#!/bin/bash

#update PingOne policy to use passphrase policy using default values for the config.

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#get id for the Basic policy
PASS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
--header 'content-type: application/x-www-form-urlencoded' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.passwordPolicies[] | select(.name=="Basic") | .id')

#set default active password policy to Passphrase
PASS_POL_SET=$(curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/passwordPolicies/$PASS_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN " \
--header 'Content-Type: application/json' \
--data-raw '{
  "id" : "'"$PASS_POL_ID"'",
      "environment" : {
        "id" : "'"$ENV_ID"'"
      },
      "name" : "Basic",
      "description" : "A relaxed standard policy to allow for maximum customer flexibility.",
      "excludesProfileData" : false,
      "notSimilarToCurrent" : false,
      "excludesCommonlyUsed" : true,
      "lockout" : {
        "failureCount" : 5,
        "durationSeconds" : 900
      },
      "length" : {
        "min" : 8,
        "max" : 255
      },
      "minCharacters" : {
        "~!@#$%^&*()-_=+[]{}|;:,.<>/?" : 1,
        "0123456789" : 1,
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" : 1,
        "abcdefghijklmnopqrstuvwxyz" : 1
      },
      "default" : true
}')

#validation
PASS_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
--header 'content-type: application/x-www-form-urlencoded' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.passwordPolicies[] | select(.name=="Basic") | .default')

#verify set true
if [ "$PASS_POL_STATUS" = true ]; then
  echo "Passphrase policy set successfully"
else
  echo "Passphrase policy not set successfully"
  exit 1
fi